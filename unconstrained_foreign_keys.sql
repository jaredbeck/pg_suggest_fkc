select relname, attname
from pg_class tbl
inner join pg_attribute col
  on col.attrelid = tbl.oid
where tbl.relnamespace = $1
  and col.attname ~ '_id$'
  and tbl.relkind = 'r'
  and not exists
  (
    select *
    from pg_constraint cst
    where cst.connamespace = $1
      and cst.conrelid = tbl.oid
      and col.attnum = any (cst.conkey)
      and cst.contype = 'f'
  )
;
