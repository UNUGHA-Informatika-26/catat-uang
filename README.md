# CatatUang

Aplikasi Flutter pencatatan pemasukan dan pengeluaran dengan Supabase Auth dan
Postgres.

## Konfigurasi Supabase

Atur `SUPABASE_URL` dan `SUPABASE_ANON_KEY` saat menjalankan aplikasi. Gunakan
Project URL dan publishable key (atau legacy anon key) dari Supabase
**Project Settings → API Keys**. Jangan gunakan atau menyimpan `service_role`
atau secret key di aplikasi.

Konfigurasi **CatatUang (Supabase)** di VS Code sudah memakai kredensial
publishable yang diberikan. Pilih konfigurasi tersebut lalu tekan F5.

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

Aktifkan **Email** di **Authentication → Providers** pada dashboard Supabase.
Jika konfirmasi email diaktifkan, pengguna perlu mengonfirmasi alamat emailnya
sebelum masuk.

## Siapkan tabel transaksi

Jalankan SQL berikut di **SQL Editor** proyek Supabase. Row Level Security
membatasi setiap pengguna ke transaksi miliknya sendiri.

```sql
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  amount bigint not null check (amount > 0),
  is_income boolean not null,
  category text not null,
  created_at timestamptz not null default now()
);

create index transactions_user_created_idx
  on public.transactions (user_id, created_at desc);

alter table public.transactions enable row level security;

grant select, insert on public.transactions to authenticated;

create policy "Users can read their own transactions"
  on public.transactions for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can add their own transactions"
  on public.transactions for insert to authenticated
  with check ((select auth.uid()) = user_id);
```

Pendaftaran, masuk, reset kata sandi, dan transaksi memakai sesi Supabase Auth.
Nama lengkap disimpan sebagai metadata pengguna; transaksi tersimpan di tabel
`transactions` dan ringkasan keuangan dihitung dari data yang dimuat.
