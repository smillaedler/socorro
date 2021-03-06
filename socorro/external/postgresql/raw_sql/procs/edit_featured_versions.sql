CREATE OR REPLACE FUNCTION edit_featured_versions(product citext, VARIADIC featured_versions text[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
-- this function allows admins to change the featured versions
-- for a particular product
BEGIN

--check required parameters
IF NOT ( nonzero_string(product) AND nonzero_string(featured_versions[1]) ) THEN
	RAISE NOTICE 'a product name and at least one version are required';
    RETURN FALSE;
END IF;

--check that all versions are not expired
PERFORM 1 FROM product_versions
WHERE product_name = product
  AND version_string = ANY ( featured_versions )
  AND sunset_date < current_date;
IF FOUND THEN
	RAISE NOTICE 'one or more of the versions you have selected is already expired';
    RETURN FALSE;
END IF;

--Remove disfeatured versions
UPDATE product_versions SET featured_version = false
WHERE featured_version
	AND product_name = product
	AND NOT ( version_string = ANY( featured_versions ) );
	
--feature new versions
UPDATE product_versions SET featured_version = true
WHERE version_string = ANY ( featured_versions )
	AND product_name = product
	AND NOT featured_version;

RETURN TRUE;

END;$$;


