class CreateCountEstimate < ActiveRecord::Migration[5.0]
  def up
    connection.execute(%q{
      CREATE OR REPLACE FUNCTION count_estimate(query text) RETURNS INTEGER AS
      $func$
      DECLARE
          rec   record;
          ROWS  INTEGER;
      BEGIN
          FOR rec IN EXECUTE 'EXPLAIN ' || query LOOP
              ROWS := SUBSTRING(rec."QUERY PLAN" FROM ' rows=([[:digit:]]+)');
              EXIT WHEN ROWS IS NOT NULL;
          END LOOP;

          RETURN ROWS;
      END
      $func$ LANGUAGE plpgsql;
    })
  end

  def down
    connection.execute(%q{
      DROP FUNCTION count_estimate(query text) CASCADE
    })
  end
end
