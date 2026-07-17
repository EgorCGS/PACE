using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Security.Cryptography;
using System.Web;

namespace PACE
{
    // Represents a user account in the PACE system.
    // A user is either a Teacher or a Student, determined by the Role field.
    // Named PaceUser rather than User because User collides with ASP.NET's
    // own IPrincipal User property that every page already exposes.
    public class PaceUser
    {
        // - Attributes -

        // Unique ID for this user, matches the UserID primary key in the database.
        // int is used because UserID is an identity column (SQL int), and every
        // foreign key that references a user (ClassEnrolments, HomeworkTasks via
        // Classes, CompletionRecords) stores this same int, so the C# type has to
        // match to avoid implicit conversions when reading/writing with ADO.NET.
        public int UserID { get; set; }

        // The username used to log in (e.g. "mbright").
        // string maps directly to the NVARCHAR column in SQL, and NVARCHAR (not
        // VARCHAR) was chosen at the database level so names are not restricted
        // to ASCII, string in C# is the natural counterpart since it is UTF-16
        // internally and needs no extra encoding/decoding step.
        public string Username { get; set; }

        // Either "Teacher" or "Student", controls which pages the user can access.
        // Stored as a plain string rather than an enum or a bit flag because the
        // database column is a small NVARCHAR of literal values, and every page's
        // Session["Role"] check compares directly against those same literal
        // strings, keeping the C# representation and the stored/session value
        // identical avoids a mapping/translation step at every read site.
        public string Role { get; set; }

        // The user's full display name (e.g. "Mrs. Bright").
        // string/NVARCHAR again, for the same Unicode reasoning as Username,
        // full names may contain accented characters or punctuation.
        public string FullName { get; set; }


        // - Methods -

        /// <summary>
        /// Generates a random 32 byte cryptographic salt value.
        /// </summary>
        /// <returns>A 32 byte array of cryptographically random data.</returns>
        // A salt is a unique random value added to each password before hashing,
        // ensuring two users with the same password still produce different hashes.
        // byte[] is used, not string, because RandomNumberGenerator produces raw
        // cryptographic bytes with no meaningful text encoding, and the Salt
        // database column is VARBINARY(32), a byte array stores and round trips
        // through ADO.NET without any base64/hex conversion that could lose data
        // or introduce bugs. 32 bytes (256 bits) is used because it comfortably
        // exceeds the SHA-256 block size, giving negligible collision risk between
        // any two generated salts.
        public static byte[] GenerateSalt()
        {
            byte[] salt = new byte[32];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }
            return salt;
        }

        /// <summary>
        /// Hashes a plain text password with the given salt using PBKDF2 (100,000 SHA-256 iterations).
        /// </summary>
        /// <param name="plainText">The plain text password to hash.</param>
        /// <param name="salt">The salt to combine with the password before hashing.</param>
        /// <returns>A 64 byte password hash.</returns>
        // The high iteration count makes brute force attacks very slow.
        // PBKDF2 (Rfc2898DeriveBytes) is chosen over a single fast hash (e.g. plain
        // SHA-256 once) because it is deliberately slow to compute, which is exactly
        // what is wanted for password storage, it makes each individual guess in an
        // offline brute force attack expensive. 100,000 iterations was the widely
        // accepted OWASP minimum for PBKDF2-HMAC-SHA256 at the time this was written,
        // balancing attacker cost against an acceptable login delay for real users.
        // SHA-256 was picked as the underlying hash function because it is the
        // .NET-supported algorithm with no known practical collision attacks,
        // unlike MD5 or SHA-1.
        // plainText is a string because that is what a user types into a login
        // form (ASP.NET TextBox.Text is always string), but the return value and
        // salt parameter are byte[] because PBKDF2 is a byte-oriented algorithm,
        // internally Rfc2898DeriveBytes UTF-8 encodes the string once and then
        // works entirely in raw bytes, matching the VARBINARY(64) PasswordHash
        // column so the result can be written straight to the database with no
        // further conversion.
        public static byte[] HashPassword(string plainText, byte[] salt)
        {
            using (var pbkdf2 = new Rfc2898DeriveBytes(
                plainText, salt, 100000,
                HashAlgorithmName.SHA256))
            {
                return pbkdf2.GetBytes(64);
            }
        }

        /// <summary>
        /// Compares two password hashes in constant time to prevent timing attacks.
        /// </summary>
        /// <param name="hash1">The first hash to compare.</param>
        /// <param name="hash2">The second hash to compare.</param>
        /// <returns>True if the hashes are identical, false otherwise.</returns>
        // A naive comparison (e.g. hash1.SequenceEqual(hash2), or a for loop that
        // returns as soon as a mismatch is found) exits early on the first byte
        // that differs, so the time taken leaks how many leading bytes matched,
        // an attacker could exploit that timing difference to guess the hash one
        // byte at a time. Instead, every byte pair is always XORed and OR'd into
        // a single accumulator (diff), so every call takes the same number of
        // operations regardless of where a mismatch occurs, no early return, no
        // information leaked through timing.
        // This method is private (unlike the public Authenticate) because hash
        // comparison is an internal implementation detail of the authentication
        // process, nothing outside this class ever needs to compare two raw hashes
        // directly, keeping it private enforces that all password verification
        // goes through Authenticate, which also handles the database lookup and
        // session setup consistently.
        private static bool CompareHashes(byte[] hash1, byte[] hash2)
        {
            // If lengths differ the hashes cannot be equal
            if (hash1.Length != hash2.Length) return false;

            // int accumulator is enough since only its zero/non-zero state
            // matters at the end, no need for a larger or different type
            int diff = 0;
            for (int i = 0; i < hash1.Length; i++)
            {
                // XOR each byte pair, any difference makes diff non zero.
                // Every iteration runs regardless of the result so far, this is
                // what makes the loop constant time rather than short-circuiting.
                diff |= hash1[i] ^ hash2[i];
            }

            // diff is zero only if every byte matched
            return diff == 0;
        }

        /// <summary>
        /// Checks a username and password against the database and, if valid, stores the user's
        /// details in the session.
        /// </summary>
        /// <param name="username">The username to authenticate.</param>
        /// <param name="password">The plain text password to verify.</param>
        /// <returns>True if the credentials matched and the session was populated, false otherwise.</returns>
        // This is the only public entry point for verifying credentials (it wraps
        // the private HashPassword/CompareHashes helpers), so every page that
        // needs to log a user in calls the same, single, consistently correct
        // code path rather than re-implementing hash comparison itself.
        public static bool Authenticate(string username, string password)
        {
            // string connection string read from Web.config via ConfigurationManager
            // rather than hardcoded, so the LocalDB file path/connection details
            // live in one place and can change without recompiling
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Query the database for the user with this username,
                // retrieving the stored hash and salt needed to verify the password.
                // A parameterised query (@Username) is used instead of string
                // concatenation so user input can never be interpreted as SQL,
                // preventing SQL injection.
                string sql = "SELECT UserID, PasswordHash, Salt, Role, FullName " +
                             "FROM Users WHERE Username = @Username";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@Username", username);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (!reader.Read())
                        {
                            // No user found with this username
                            return false;
                        }

                        // Read the stored hash and salt from the database.
                        // Cast straight to byte[] because SqlDataReader returns the
                        // VARBINARY columns as boxed byte arrays already, no parsing
                        // or conversion needed, unlike the string columns below.
                        byte[] storedHash = (byte[])reader["PasswordHash"];
                        byte[] storedSalt = (byte[])reader["Salt"];

                        // Hash the entered password using the same salt that was
                        // used when the password was originally created. Reusing
                        // the stored salt (rather than generating a new one) is
                        // essential, PBKDF2 only reproduces the same hash when the
                        // same salt, iteration count and algorithm are used.
                        byte[] enteredHash = HashPassword(password, storedSalt);

                        // Compare the two hashes in constant time
                        if (CompareHashes(enteredHash, storedHash))
                        {
                            // Match found, store user details in the session.
                            // Session values are stored as string (via ToString())
                            // because ASP.NET Session state is a loosely typed
                            // object dictionary, storing plain strings avoids
                            // repeated boxing/unboxing and casting on every page
                            // that reads Session["Role"] etc, and keeps the value
                            // directly comparable to the literal "Teacher"/"Student"
                            // strings used throughout the role-check pattern.
                            HttpContext.Current.Session["UserID"] = reader["UserID"].ToString();
                            HttpContext.Current.Session["Role"] = reader["Role"].ToString();
                            HttpContext.Current.Session["FullName"] = reader["FullName"].ToString();
                            return true;
                        }

                        return false;
                    }
                }
            }
        }

        /// <summary>
        /// Inserts a new PaceUser account into the database with a freshly generated salt and hash.
        /// </summary>
        /// <param name="username">The username for the new account.</param>
        /// <param name="plainTextPassword">The plain text password to hash and store.</param>
        /// <param name="role">The account role, either "Teacher" or "Student".</param>
        /// <param name="fullName">The full display name for the new account.</param>
        /// <returns>True if the account was created, false if the username was already taken.</returns>
        // Generates a fresh salt and hashes the password before storing,
        // so plain text passwords are never written to the database.
        // A brand new salt is generated per user (never reused between accounts)
        // so that even if two users pick the same password, their stored hashes
        // are different, this defeats precomputed rainbow table attacks.
        public static bool CreateUser(string username, string plainTextPassword,
                                      string role, string fullName)
        {
            byte[] salt = GenerateSalt();
            byte[] passwordHash = HashPassword(plainTextPassword, salt);

            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Parameterised INSERT, same SQL injection reasoning as
                // Authenticate, user-supplied values never touch the SQL string
                string sql = "INSERT INTO Users (Username, PasswordHash, Salt, Role, FullName) " +
                             "VALUES (@Username, @PasswordHash, @Salt, @Role, @FullName)";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@Username", username);
                    cmd.Parameters.AddWithValue("@PasswordHash", passwordHash);
                    cmd.Parameters.AddWithValue("@Salt", salt);
                    cmd.Parameters.AddWithValue("@Role", role);
                    cmd.Parameters.AddWithValue("@FullName", fullName);

                    try
                    {
                        // int rowsAffected because ExecuteNonQuery returns the count
                        // of rows changed, comparing it to 1 confirms exactly one
                        // account was created rather than assuming success
                        int rowsAffected = cmd.ExecuteNonQuery();
                        return rowsAffected == 1;
                    }
                    catch (SqlException ex)
                    {
                        // Error code 2601 and 2627 both mean a duplicate username was entered.
                        // These specific numbers are checked (rather than catching
                        // SqlException generically) so a duplicate username is treated
                        // as an expected, recoverable case (return false) while any
                        // other database error still propagates and is not silently
                        // swallowed, that distinction matters for reasonableness
                        // checking further up the call stack.
                        if (ex.Number == 2601 || ex.Number == 2627)
                            return false;

                        throw;
                    }
                }
            }
        }

        /// <summary>
        /// Gets the role of the currently logged in user from the session.
        /// </summary>
        /// <returns>"Teacher" or "Student" if a user is logged in, otherwise null.</returns>
        // Returns null (rather than an empty string) when nothing is logged in,
        // so callers can use a straightforward null check to detect "not logged
        // in", the same convention every page's role-check at the top of Page_Load
        // relies on.
        public static string GetRole()
        {
            return HttpContext.Current.Session["Role"] != null
                ? HttpContext.Current.Session["Role"].ToString()
                : null;
        }

        /// <summary>
        /// Ends the current user's session, logging them out.
        /// </summary>
        // Session.Abandon() is used rather than clearing individual keys, so any
        // future values added to the session are also discarded on logout without
        // this method needing to be updated.
        public static void Logout()
        {
            HttpContext.Current.Session.Abandon();
        }
    }
}
