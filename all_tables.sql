select relname
from pg_class
where relnamespace = $1
;
