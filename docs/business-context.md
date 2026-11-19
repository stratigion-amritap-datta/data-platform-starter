# Business context

The outcome is two tables operations and finance can share. `fct_orders` keeps one row per order as status, cancellation, and refund change. `dim_customers` keeps every account, including people who signed up and never bought. Recognized revenue is zero when an order is cancelled, and otherwise the order total minus the refund on the row.

A direct-to-consumer retailer needs that base because the current pack is rebuilt by hand from separate extracts. Status changes, refunds, and non-buyers show up late, twice, or not at all. Sample seeds stand in for the store extract. The marts are what a team would publish once the same logic runs on a live feed.

## The business problem

Checkout creates an order. Fulfillment moves it through `placed`, `paid`, `shipped`, and `delivered`. Some orders are `cancelled` before they leave. Some are `returned` after payment, in full or in part. Each of those events changes the same order.

Operations counts what is still in flight, what was cancelled, what came back, and how long after signup the customer bought. Finance counts order total, refund, and recognized revenue on that same order.

Separate extracts split those counts. A cancelled order removed from a finance sheet cannot be used in a cancellation rate. A returned order zeroed because the status says `returned` hides a partial refund. A customer who never ordered disappears, so acquisition looks cleaner than the signup list.

The operating question: for any day, how many orders are at each stage, what revenue remains after cancellations and refunds, and which customers have bought, repeated, or never ordered?

## Who feels the pain

**Operations** owns fulfillment. They need the current status of every order, including orders placed weeks ago whose status moved this week. A late ship that never lands in the report becomes a customer issue they hear about before the dashboard does.

**Finance** owns the commercial number. They need a revenue figure that survives a status change: cancelled orders at zero, full refunds at zero, partial refunds at order total minus the amount returned. Rebuilding that in a spreadsheet every week is where the close slips.

**Growth and CRM** own the account list. They need customers who have not ordered yet. A report built only from the order export treats signup as the same event as purchase and cannot show who never converted.

**The person preparing the weekly pack** sits between those groups. They export, paste, dedupe, and explain why yesterday's total moved. The grain is unstable, and the revenue rule lives in a cell.

## What is currently broken or slow

The store already has the facts. The reporting path drops them.

- **One order becomes many rows.** A status export appended to last week's file counts the same `order_id` again when it moves from `paid` to `shipped`. Totals inflate until someone dedupes by hand.
- **Late updates miss the cutoff.** Fulfillment can update an October order in mid-November. A report that only loads rows newer than the last timestamp leaves that order on its old status.
- **Cancellations vanish.** Dropping cancelled orders makes revenue look tidy and makes the cancellation rate impossible to compute.
- **Returns are treated as a single outcome.** A full refund and a partial refund share the status `returned`. Zeroing every returned order overstates the loss. On this sample, `O10009` is a 37.38 order with 20.00 refunded and 17.38 still recognized. Two other returns are refunded in full.
- **Lifetime value is undercounted.** Building customer totals from whatever arrived in the latest load drops older orders. A two-day operational refresh would then rewrite a customer's history every day.
- **Non-buyers are invisible.** Theo Berg (`C1015`) is on the customer extract and has no orders. An orders-only report cannot show that account.
- **The rule is unchecked.** Nothing fails when a refund exceeds the order total or when a discount exceeds the merchandise amount. The error shows up later, in a meeting.

The sample is 15 customers and 36 orders, small enough to reconcile in an afternoon. The same gaps on a full catalog consume the week, and the next status change invalidates the pack.

## What this data platform starter solves

The starter publishes the two tables named above and pins the definitions they use.

`marts.fct_orders` merges on `order_id`, so a status change updates the row already there. Orders whose source `updated_at` falls inside a two-day lookback of the latest watermark are reprocessed. That window picks up a late fulfillment update, such as `O10021`, placed in October and marked shipped on 16 November. Orders outside the window stay as they are. The width of the window is `orders_lookback_days`, so a backfill is a parameter change.

Cancelled orders stay in the table, so the cancellation count and the revenue number come from the same grain. In-flight `paid` and `shipped` orders remain visible to operations and are included in the commercial snapshot. This is an operating view for process and revenue reporting, not an accounting subledger.

`marts.dim_customers` aggregates the full enriched order set. The lookback window cannot erase older purchases from a customer total.

Upstream, staging only cleans and types the extract. The intermediate model holds the join and the amount logic. Tests reject duplicate keys, unknown statuses, orphan orders, and any row that breaks the revenue rule. A change to the rule fails the build.

On the sample, the pack is defendable: 3 cancelled orders at 0 recognized revenue, 21 delivered orders at 2,244.10, returned orders at 17.38 after refunds, and one customer with no orders. Country and customer rankings use the same revenue column, so the slices match the total.

## How this is used in an advisory or implementation engagement

Use the starter to fix the metric contract before connecting production systems.

1. **Agree the decisions the pack has to support.** Typical ones are in-flight backlog, cancellation rate, refund leakage split into full and partial, recognized revenue for the period, and the count of accounts that have not ordered. Write those down with the operators who will be questioned on them.
2. **Lock the definitions with finance and operations in the same room.** Status list, what counts as recognized revenue, whether in-flight orders are included, and how a partial refund is stored. The intermediate model and `assert_order_amounts_are_consistent` are that contract in code. Change the rule there, in front of both teams, and rerun the tests.
3. **Land a bounded extract.** Replace the seed files with a few weeks of real orders and customers from the store. Keep the column names or map them in staging. Run `dbt seed`, `dbt run`, and `dbt test`. The client sees their own cancellations, partial refunds, late shipments, and non-buyers on the marts the same day.
4. **Walk the exceptions.** Pick a full refund, a partial refund, a cancellation, an order updated long after checkout, and an account with no orders. If the business disagrees with a number, the disagreement is about the rule, and the rule has one implementation.
5. **Set the operating cadence.** Daily refresh plus a two-day lookback covers a missed run and late fulfillment updates. Widen `orders_lookback_days` for a correction window. Full refresh when the measure itself changes. Customer totals stay on the full history regardless of that window.
6. **Promote the same models.** Swap the seeds for the live landing tables, keep the staging-to-mart path and the tests, and point the weekly pack at `fct_orders` and `dim_customers`. The engagement deliverable is a reported grain, a written revenue rule, and a build that fails when either one breaks.

The sample data rehearses that conversation. The implementation work is replacing the extract and holding the definitions still.
