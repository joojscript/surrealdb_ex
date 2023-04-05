-- ------------------------------
-- OPTION
-- ------------------------------

OPTION IMPORT;

-- ------------------------------
-- SCOPES
-- ------------------------------

DEFINE SCOPE allusers SESSION 2w SIGNUP (CREATE user SET user = $user, pass = crypto::argon2::generate($pass)) SIGNIN (SELECT * FROM user WHERE user = $user AND crypto::argon2::compare(pass, $pass));

