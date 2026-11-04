# Decisions

## Assumptions
See the table in docs/PRD.md (A1-A7). For each: gap, assumption, why, how easy to change.

## Key design decisions
<!-- Decision / Alternatives / Why / Trade-off. e.g. backend required, Core Swift Package, Mailpit, Fastify, @Observable -->

## Dropped or simplified, and why
<!-- Each with a one-line reason tied to the time-box -->

## How the design grows beyond the PoC
- Product source: `ProductSource` port; swap the adapter, iOS unchanged.
- Email provider: `EmailSender` port; SES or similar later (AWS-compatible).
- Look and feel: `DesignSystem/` tokens and components.
- Backend: Dockerised and stateless; deployable to ECS or Lambda.

## What I would do next with another day
<!-- Defensible items only, e.g. persist enquiries because email failure loses them -->
