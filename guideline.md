# Real-time Notifications Guideline (Turbo Streams + Action Cable)

This guide explains how to broadcast **immediate, real-time notifications** to a
recipient's browser whenever a new `Notification` record is created — with no page
refresh.

It works because **Turbo Streams run on top of Action Cable**. When a `Notification`
row is saved, the app pushes `<turbo-stream>` fragments over that recipient's
personal Action Cable channel. Any page the recipient has open that subscribes to
the stream (`turbo_stream_from`) applies the fragments instantly.

> The pattern below is already implemented. This document is your reference for
> how it fits together and how to extend it.

---

## 1. How it works (the moving pieces)

```
                            ┌────────────────────────────┐
                            │  Action Cable server        │
                            │  (solid_cable adapter)      │
                            └─────────────▲──────────────┘
                                          │ broadcast
┌───────────────────┐  after_create_commit │
│ Notification model│ ──────────►  broadcast_prepend_to / broadcast_replace_to
└───────────────────┘
```

1. A controller (or job) creates a `Notification` via `notify_user` / `notify_role`.
2. The model's `after_create_commit` callback broadcasts Turbo Stream fragments to
   the `recipient`'s stream (`user:<id>`).
3. The recipient's browser keeps an Action Cable connection open because every page
   that cares renders `<%= turbo_stream_from current_user %>`.
4. Turbo receives the fragments and updates the DOM in place.

---

## 2. The model side — `app/models/notification.rb`

This is the only place you need to touch to make new notifications appear
immediately:

```ruby
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"

  enum :status, { unread: 0, read: 1 }, default: 0

  scope :recent, -> { order(created_at: :desc) }

  # Push every new notification to its recipient in real time via Action Cable.
  after_create_commit :broadcast_new_notification

  private
    def broadcast_new_notification
      # 1) Insert the new card at the top of the recipient's notification list.
      broadcast_prepend_to recipient, target: "notifications-list"

      # 2) Refresh the header bell dot (idempotent partial, safe to replace).
      broadcast_replace_to recipient,
        target: "notification-badge",
        partial: "notifications/bell_badge",
        locals: { user: recipient }
    end
end
```

Key points:

- **`after_create_commit`** (not `after_create`) guarantees the record is committed
  to the DB before broadcasting, so the stream fragment and the persisted row stay
  consistent.
- **`broadcast_*_to recipient`** names the stream after the recipient object
  (`user:<id>`), so **each recipient only receives their own notifications**.
- **`Turbo::Broadcastable`** is auto-included on `ActiveRecord::Base` by
  `turbo-rails`, so methods like `broadcast_prepend_to` are available on every model.

---

## 3. Creating a notification (the caller side)

Use the existing helpers in `ApplicationController` — they remain the single entry
point, and the model callback handles broadcasting for you:

```ruby
# To one user
notify_user(
  recipient: @reservation.user,
  title: "Reservation confirmed",
  body: "Your table is confirmed."
)

# To everyone with a given role
notify_role(:receptionist,
  title: "New reservation request",
  body: "A guest requested a table."
)
```

You can also create a record inline anywhere (`Notification.create!` / `.create`) —
the `after_create_commit` callback still fires and broadcasts automatically.

---

## 4. Subscribing a page — `turbo_stream_from`

Every page that should live-update must **open the Action Cable connection** for
that recipient with `<%= turbo_stream_from %>`:

```erb
<%= turbo_stream_from current_user %>
```

### Where it is already placed

- `app/views/notifications/index.html.erb` — so the list updates live.

```erb
<div class="min-h-screen bg-[#f4e6e2] ...">
  <%= turbo_stream_from current_user %>   <%-- opens the stream --%>
  ...
  <div id="notifications-list" class="space-y-4">
    <%= render @notifications %>
  </div>
</div>
```

- `app/views/layouts/_header.html.erb` — so the bell dot updates on **every page**.

```erb
<% if current_user %>
  <%= turbo_stream_from current_user %>
  <%= link_to notifications_path do %>
    <div class="relative ...">
      <%= render "notifications/bell_badge", user: current_user %>
      ...
    </div>
  <% end %>
<% end %>
```

> ⚠️ **Golden rule:** the stream can only update DOM elements that are **already
> present on that page** and are **not** wrapped inside the `<turbo_stream_from>`
> tag. Put the tag near the top of the layout so it wraps as little as possible.
---

## 5. The partials the broadcast renders

Because broadcasts render partials, extract every card/badge you broadcast into a
partial with a **stable `id`** so Turbo can target it.

### `app/views/notifications/_notification.html.erb` (one card)

```erb
<article id="<%= dom_id(notification) %>" class="rounded-lg ...">
  ...
  <h2 ...><%= notification.title %></h2>
  <p ...><%= notification.body %></p>
  ...
</article>
```

`dom_id(notification)` yields the Rails-standard DOM id (`notification_<id>`), which
keeps broadcast prepends from duplicating elements and makes them targetable.

### `app/views/notifications/_bell_badge.html.erb` (the header dot)

```erb
<div id="notification-badge">
  <% if user&.notifications&.unread&.exists? %>
    <span class="absolute top-0 right-0 h-2 w-2 rounded-full bg-red-600"></span>
  <% end %>
</div>
```

Because the partial is fully idempotent and keyed by the stable `#notification-badge`
id, `broadcast_replace_to` can safely swap it out on every page.

---

## 6. Configuring the Action Cable adapter

The transport is configured in `config/cable.yml`:

```yaml
development:
  adapter: async          # in-process; good for local dev + console tests

test:
  adapter: test

production:
  adapter: solid_cable    # database-backed adapter (no Redis needed)
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

- **Dev / test** use the `async` / `test` adapters — simplest for local work.
- **Production** uses `solid_cable` (the solid-cable gem is already in the Gemfile),
  which needs its own `cable` database connection.
---

## 7. Available broadcast actions (quick reference)

Within a model callback you can call any of these (all also have `_later` /
`_later_to` async variants that offload rendering to a job):

| Action               | Method                      | Purpose                              |
|----------------------|-----------------------------|--------------------------------------|
| Prepend              | `broadcast_prepend_to`      | Insert before existing content       |
| Append               | `broadcast_append_to`       | Insert after existing content        |
| Replace              | `broadcast_replace_to`      | Swap one element for another         |
| Update               | `broadcast_update_to`       | Replace content of an existing target|
| Remove               | `broadcast_remove_to`       | Remove an element                    |
| Refresh (whole page) | `broadcast_refresh_later_to`| Re-render the page smoothly          |

Example — remove a card and keep the badge correct:

```ruby
broadcast_remove_to recipient, target: dom_id(self)
broadcast_replace_to recipient, target: "notification-badge",
  partial: "notifications/bell_badge", locals: { user: recipient }
```

> Rule of thumb: use the synchronous `broadcast_*` inside `after_create_commit`
> (as done here) for immediate delivery. If you broadcast within a hot loop
> (e.g. `notify_role` creating many rows) and want to reduce per-request rendering,
> switch those specific calls to the `*_later_to` variants instead.

---

## 8. Testing it

Model-level tests use `Turbo::Broadcastable::TestHelper` (helpers live in
`lib/turbo/broadcastable/test_helper.rb`):

```ruby
require "test_helper"
require "turbo/broadcastable/test_helper"

class NotificationTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "broadcasts a prepend and a badge update on create" do
    recipient = users(:one)

    assert_turbo_stream_broadcasts recipient, count: 2 do
      Notification.create!(recipient: recipient, title: "Table ready", body: "Your table is ready.")
    end
  end

  test "prepends the new card into the notifications list" do
    recipient = users(:one)

    streams = capture_turbo_stream_broadcasts recipient do
      Notification.create!(recipient: recipient, title: "Promotion", body: "50% off desserts.")
    end

    assert_equal "prepend", streams.first["action"]
    assert_equal "notifications-list", streams.first["target"]
    assert_includes streams.first.to_html, "Promotion"
  end
end
```

Run them with:

```bash
bin/rails test test/models/notification_test.rb
```

> If the helpers are missing in a custom test class, require them explicitly (the
> engine only auto-includes them when ActiveJob is loaded):
> `require "turbo/broadcastable/test_helper"` then
> `include Turbo::Broadcastable::TestHelper`.
---

## 9. Manual end-to-end check (dev)

1. Start the server: `bin/dev` (or `bin/rails server`). Dev uses the `async`
   adapter, so everything runs in-process.
2. Log in as the recipient in **two** browser windows/tabs (one open to
   `/notifications`, one on any other page so you can see the header bell).
3. Trigger a notification — e.g. create a reservation (fires
   `notify_role(:receptionist, ...)` / `notify_role(:admin, ...)`), or run in the
   **web console** on the running dev page:

   ```ruby
   notify_user(recipient: User.find_by(email: "you@example.com"),
               title: "Hello", body: "Live-updating now!")
   ```

4. Watch: the new card appears at the top of the open `/notifications` page and the
   red bell dot appears in the header — no refresh.

---

## 10. Checklist when adding a new notification flow

- [ ] Create the `Notification` via `notify_user` / `notify_role` (or directly) —
      the model callback broadcasts automatically, **no controller broadcast code
      needed**.
- [ ] If you changed what a card/badge renders, update the corresponding partial.
- [ ] Ensure the page you want to update live calls `<%= turbo_stream_from current_user %>`.
- [ ] Make sure the stream targets (`notifications-list`, `notification-badge`)
      exist on that page **outside** the `turbo_stream_from` wrapper and have stable ids.
- [ ] Add or extend a model test asserting the broadcast fires with the right action
      and target.
  `turbo-rails`, so methods like `broadcast_prepend_to` are available on every model.