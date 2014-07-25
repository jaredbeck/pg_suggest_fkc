select relname, attname
from pg_class tbl
inner join pg_attribute col
  on col.attrelid = tbl.oid
where tbl.relnamespace = 2200
  and col.attname ~ '_id$'
  and tbl.relkind = 'r'
  and not exists
  (
    select *
    from pg_constraint cst
    where cst.connamespace = 2200
      and cst.confrelid = tbl.oid
      and col.attnum = any (cst.confkey)
  )
;