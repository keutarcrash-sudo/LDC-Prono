-- ============================================================
-- Schéma Supabase — Pronostics Ligue des Champions (Arena)
-- À coller dans Supabase > SQL Editor > New query > Run
-- ============================================================

-- Un joueur = identifié par son numéro de téléphone (persiste sur toute la saison)
create table joueurs (
  id uuid primary key default gen_random_uuid(),
  phone text unique not null,
  pseudo text not null,
  created_at timestamptz default now()
);

-- Une soirée de Ligue des Champions à l'Arena, avec son QR code unique
create table soirees (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  code_qr text unique not null,
  label text,
  recompense text default '1 boisson offerte au choix',
  recompense_choix text,
  recompense_choisie_at timestamptz,
  created_at timestamptz default now()
);

-- Les matchs joués lors d'une soirée
create table matchs (
  id uuid primary key default gen_random_uuid(),
  soiree_id uuid references soirees(id) on delete cascade,
  external_match_id text,
  equipe_domicile text not null,
  equipe_exterieur text not null,
  logo_domicile text,
  logo_exterieur text,
  coup_envoi timestamptz not null,
  score_domicile int,
  score_exterieur int,
  statut text default 'SCHEDULED',
  created_at timestamptz default now()
);

-- Les pronostics des joueurs, match par match
create table pronostics (
  id uuid primary key default gen_random_uuid(),
  joueur_id uuid references joueurs(id) on delete cascade,
  match_id uuid references matchs(id) on delete cascade,
  score_domicile_predit int not null,
  score_exterieur_predit int not null,
  points int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (joueur_id, match_id)
);

-- ============================================================
-- Barème de points : 5 = score exact / 3 = bonne différence de
-- buts / 1 = bon vainqueur (ou bon nul) / 0 = faux
-- ============================================================
create or replace function calculate_points(pred_h int, pred_a int, act_h int, act_a int)
returns int as $$
begin
  if act_h is null or act_a is null then
    return 0;
  end if;
  if pred_h = act_h and pred_a = act_a then
    return 5;
  end if;
  if (pred_h - pred_a) = (act_h - act_a) then
    return 3;
  end if;
  if sign(pred_h - pred_a) = sign(act_h - act_a) then
    return 1;
  end if;
  return 0;
end;
$$ language plpgsql immutable;

-- Recalcule les points de tous les pronostics d'un match dès que son score final est renseigné
create or replace function recalc_points_on_match_result()
returns trigger as $$
begin
  if new.score_domicile is not null and new.score_exterieur is not null
     and (old.score_domicile is distinct from new.score_domicile
          or old.score_exterieur is distinct from new.score_exterieur) then
    update pronostics
    set points = calculate_points(score_domicile_predit, score_exterieur_predit, new.score_domicile, new.score_exterieur)
    where match_id = new.id;
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_recalc_points
after update on matchs
for each row execute function recalc_points_on_match_result();

-- Empêche de pronostiquer (ou modifier) un match une fois le coup d'envoi donné
create or replace function check_pronostic_timing()
returns trigger as $$
declare
  v_kickoff timestamptz;
begin
  select coup_envoi into v_kickoff from matchs where id = new.match_id;
  if v_kickoff is null then
    raise exception 'Match introuvable';
  end if;
  if now() >= v_kickoff then
    raise exception 'Les pronostics pour ce match sont clôturés (coup d''envoi déjà donné)';
  end if;
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_check_pronostic_timing
before insert or update on pronostics
for each row execute function check_pronostic_timing();

-- ============================================================
-- Classements
-- ============================================================
create or replace view classement_soiree as
select
  s.id as soiree_id,
  j.id as joueur_id,
  j.pseudo,
  sum(p.points) as points_soiree
from pronostics p
join matchs m on m.id = p.match_id
join soirees s on s.id = m.soiree_id
join joueurs j on j.id = p.joueur_id
group by s.id, j.id, j.pseudo;

create or replace view classement_saison as
select
  j.id as joueur_id,
  j.pseudo,
  sum(p.points) as points_total
from pronostics p
join joueurs j on j.id = p.joueur_id
group by j.id, j.pseudo
order by points_total desc;

-- ============================================================
-- Accès public (pas de compte/mot de passe pour les joueurs)
-- Sécurité minimale volontaire pour un jeu bar/Arena à petit
-- enjeu (des lots, pas de l'argent). Ne partage pas le lien
-- d'admin.html publiquement : n'importe qui avec ce lien peut
-- créer/modifier des soirées et des matchs.
-- ============================================================
alter table joueurs enable row level security;
alter table soirees enable row level security;
alter table matchs enable row level security;
alter table pronostics enable row level security;

create policy "lecture publique joueurs" on joueurs for select using (true);
create policy "creation publique joueurs" on joueurs for insert with check (true);
create policy "maj publique joueurs" on joueurs for update using (true);

create policy "lecture publique soirees" on soirees for select using (true);
create policy "ecriture publique soirees" on soirees for insert with check (true);
create policy "maj publique soirees" on soirees for update using (true);
create policy "suppr publique soirees" on soirees for delete using (true);

create policy "lecture publique matchs" on matchs for select using (true);
create policy "ecriture publique matchs" on matchs for insert with check (true);
create policy "maj publique matchs" on matchs for update using (true);
create policy "suppr publique matchs" on matchs for delete using (true);

create policy "lecture publique pronostics" on pronostics for select using (true);
create policy "creation publique pronostics" on pronostics for insert with check (true);
create policy "maj publique pronostics" on pronostics for update using (true);

-- ============================================================
-- Migration — à coller et exécuter une seule fois dans le SQL
-- Editor si ta base a été créée avant l'ajout du champ "recompense"
-- (sans risque de la relancer plusieurs fois par erreur).
-- ============================================================
alter table soirees add column if not exists recompense text default '1 boisson offerte au choix';
alter table soirees add column if not exists recompense_choix text;
alter table soirees add column if not exists recompense_choisie_at timestamptz;
alter table matchs add column if not exists logo_domicile text;
alter table matchs add column if not exists logo_exterieur text;
