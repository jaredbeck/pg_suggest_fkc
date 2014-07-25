pg_suggest_fkc
==============

Suggests [foreign key constraints][1] that your [rails][2] app's 
database may be missing.

Suggestions are based on rails' conventions for naming database
objects.

Currently, requires proficiency with postgres' [system catalogs][3].

[1]: http://www.postgresql.org/docs/9.3/static/ddl-constraints.html#DDL-CONSTRAINTS-FK "Chapter 5.3.5. Foreign Keys"
[2]: http://rubyonrails.org/ 
[3]: http://www.postgresql.org/docs/9.3/static/catalogs.html "Chapter 47. System Catalogs"
