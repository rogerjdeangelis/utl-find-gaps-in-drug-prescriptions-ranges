%let pgm=utl-find-gaps-in-drug-prescriptions-ranges;

Create a table that just the gaps in drug prescription ranges

Stackoverflow
https://tinyurl.com/sa3bkyk
https://stackoverflow.com/questions/69086900/determining-gaps-in-overlapping-time-ranges

also check out
https://github.com/rogerjdeangelis?tab=repositories&q=overlap&type=&language=&sort=
https://github.com/rogerjdeangelis?tab=repositories&q=overlap&type=&language=&sort=

TWO SOLUTIONS

   1. SQL
      seestevecode
      https://stackoverflow.com/users/1321415/seestevecode

   2. HASH
      richard
      https://stackoverflow.com/users/1249962/richard


/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

select out gaps in overlapping ranges

Note Beg and End Sunrise

data have;
  input ID $ BEG END;
cards4;
A 1 3
A 5 8
B 1 3
B 4 5
B 8 9
;;;;
run;quit;

Up to 40 obs WORK.HAVE total obs=5

Obs    ID    BEG    END

 1     A      1      3
 2     A      5      8
 3     B      1      3
 4     B      4      5
 5     B      8      9

WHAT I WANT (Just the GAP records)

Up to 40 obs WORK.HAVE total obs=5

Obs    ID    BEG    END

       A      1      3
GAP    A      3      5   GAP
       A      5      8

       B      1      3
GAP    A      3      5   GAP
       B      4      5
GAP    B      5      8   GAP
       B      8      9


/*           _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| `_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
*/

SQL

Up to 40 obs WORK.GAPS_SQL total obs=3

Obs    ID    LAST_END    NEXT_BEG

 1     A         3           5
 2     B         3           4
 3     B         5           8

HASH

Up to 40 obs WORK.WANT total obs=3

              GAP_
Obs    ID    START    GAP_END

 1     A       3         5
 2     B       3         4
 3     B       5         8

/*
 _ __  _ __ ___   ___ ___  ___ ___
| `_ \| `__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|        _
 ___  __ _| |
/ __|/ _` | |
\__ \ (_| | |
|___/\__, |_|
        |_|
*/

proc sql;
    create table gaps_sql as
        select distinct a.id
                    ,   a.end as last_end

                   ,   b.beg as next_beg
        from            have a
        inner join      have b
        on              a.end < b.beg
            and         a.id = b.id
            and         b.beg = (
                            select min(beg)
                            from have c
                            where c.beg > a.end
                                and c.id = b.id
                            )
        where           not exists (
                            select  * from have d
                            where   d.beg < a.end
                                and d.end > a.end
                                and d.id = a.id
                            )
        order by        a.id, a.end
;quit;

 _               _
| |__   __ _ ___| |__
| `_ \ / _` / __| `_ \
| | | | (_| \__ \ | | |
|_| |_|\__,_|___/_| |_|

data want(keep=id gap_start gap_end);
  length id $1 beg end 8;

  if _n_ = 1 then do;
    declare hash ranges(ordered:'a');
    ranges.defineKey('id', 'beg', 'end');
    ranges.defineDone();
    call missing (id, beg, end);
  end;

  set have end=done;
  rc = ranges.add();

  if done then do;
    declare hiter i1('ranges');

    do while (i1.next()=0);
      if id ne lag(id) then do;
        right = end;
      end;
      else do;
        if beg > right then do;
          * gap;
          gap_start = right;
          gap_end = beg;
          output;
          right = end;
        end;
        else do;
          * overlap, possible range extension;
          right = max(right, end);
        end;
      end;
    end;
  end;
run;

                _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|
