-- Allow the application user to connect to the database.
GRANT CONNECT
ON DATABASE phishing_detector
TO phishing_app;

-- Allow access to objects inside the public schema.
GRANT USAGE
ON SCHEMA public
TO phishing_app;

-- Allow reading and adding scan records.
GRANT SELECT, INSERT
ON TABLE public.scans
TO phishing_app;

GRANT USAGE ON SEQUENCE public.scans_id_seq TO phishing_app;