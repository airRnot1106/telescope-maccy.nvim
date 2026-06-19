#!/usr/bin/env bash
# Seed a sample Maccy `Storage.sqlite` for the VHS demo.
#
# The real Maccy store lives under ~/Library/Containers and holds the user's
# actual clipboard history, so we never record that into a committed GIF.
# Instead we mirror Maccy's Core Data schema and insert a handful of fake,
# representative entries with timestamps relative to "now" so the relative-time
# column ("2m ago", "1h ago", …) renders nicely at recording time.
set -euo pipefail

db="${1:?usage: seed.sh <path-to-Storage.sqlite>}"
rm -f "$db" "$db-wal" "$db-shm"

now="$(date +%s)"
# Maccy stores Core Data timestamps: seconds since 2001-01-01 (unix - 978307200).
epoch=978307200
# ago <seconds> -> Core Data timestamp for an entry copied <seconds> ago.
ago() { echo "$((now - $1 - epoch))"; }

text="public.utf8-plain-text"

sqlite3 "$db" <<SQL
CREATE TABLE ZHISTORYITEM (Z_PK INTEGER PRIMARY KEY, ZLASTCOPIEDAT REAL, ZPIN VARCHAR);
CREATE TABLE ZHISTORYITEMCONTENT (Z_PK INTEGER PRIMARY KEY, ZITEM INTEGER, ZTYPE VARCHAR, ZVALUE BLOB);

INSERT INTO ZHISTORYITEM VALUES (1, $(ago 45),     'p');
INSERT INTO ZHISTORYITEM VALUES (2, $(ago 120),    NULL);
INSERT INTO ZHISTORYITEM VALUES (3, $(ago 600),    NULL);
INSERT INTO ZHISTORYITEM VALUES (4, $(ago 3600),   NULL);
INSERT INTO ZHISTORYITEM VALUES (5, $(ago 10800),  NULL);
INSERT INTO ZHISTORYITEM VALUES (6, $(ago 86400),  NULL);
INSERT INTO ZHISTORYITEM VALUES (7, $(ago 172800), NULL);

INSERT INTO ZHISTORYITEMCONTENT VALUES (1, 1, '$text',
  CAST('https://github.com/airRnot1106/telescope-maccy.nvim' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (2, 2, '$text',
  CAST('git commit --amend --no-edit' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (3, 3, '$text',
  CAST('local function greet(name)
  return "Hello, " .. name
end' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (4, 4, '$text',
  CAST('TODO: write the vimdoc section' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (5, 5, '$text',
  CAST('SELECT * FROM ZHISTORYITEMCONTENT;' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (6, 6, '$text',
  CAST('https://neovim.io' AS BLOB));
INSERT INTO ZHISTORYITEMCONTENT VALUES (7, 7, '$text',
  CAST('The quick brown fox jumps over the lazy dog' AS BLOB));
SQL
