# My Direct Debits — Expo + PWA

A focused mobile/PWA client for the existing Personal Budget Supabase database. It reads and writes the existing `public.direct_debits` JSONB records; there is no data migration or duplicate database.

## Run

1. `npm install`
2. Copy `.env.example` to `.env` and set the Supabase publishable key.
3. `npx expo start` for Expo Go, or `npm run web` for the PWA/web client.

## Security

This first client preserves the current database setup so the existing Railway finance site is not broken. The legacy `direct_debits` table currently has RLS disabled. Do not treat the publishable key as authorization. The next hardening step is to migrate both the Railway client and this client to an owner-scoped RLS model together.

## Features

Current month dashboard, month navigation, totals, Lloyds/Monzo account cards, search, status/account filters, add/edit/delete, mark paid/pending, and copy missing direct debits from the previous month.
