using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace PACE
{
    // Represents a user account in the PACE system.
    // A user is either a Teacher or a Student, determined by the Role field.
    public class PaceUser
    {
        // - Attributes -

        // Unique ID for this user, matches the UserID primary key in the database
        public int UserID { get; set; }

        // The username used to log in (e.g. "mbright")
        public string Username { get; set; }

        // Either "Teacher" or "Student", controls which pages the user can access
        public string Role { get; set; }

        // The user's full display name (e.g. "Mrs. Bright")
        public string FullName { get; set; }


        // - Methods -

        // Generates a random 32 byte salt value.
        // A salt is a unique random value added to each password before hashing,
        // ensuring two users with the same password still produce different hashes.
        public static byte[] GenerateSalt()
        {
            byte[] salt = new byte[32];
            using (RandomNumberGenerator rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }
            return salt;
        }

        // Takes a plain text password and a salt, and produces a secure 64 byte hash
        // using the PBKDF2 algorithm with 100,000 iterations of SHA256.
        // The high iteration count makes brute force attacks very slow.
        public static byte[] HashPassword(string plainText, byte[] salt)
        {
            using (var pbkdf2 = new Rfc2898DeriveBytes(
                plainText, salt, 100000,
                HashAlgorithmName.SHA256))
            {
                return pbkdf2.GetBytes(64);
            }
        }

        // Compares two password hashes in constant time.
        // This prevents timing attacks where an attacker measures how long
        // comparisons take to figure out parts of the password.
        private static bool CompareHashes(byte[] hash1, byte[] hash2)
        {
            // If lengths differ the hashes cannot be equal
            if (hash1.Length != hash2.Length) return false;

            int diff = 0;
            for (int i = 0; i < hash1.Length; i++)
            {
                // XOR each byte pair, any difference makes diff non zero
                diff |= hash1[i] ^ hash2[i];
            }

            // diff is zero only if every byte matched
            return diff == 0;
        }

        // Checks the username and password against the database.
        // If they match, stores the user's ID, role and full name in the session
        // and returns true. If they don't match, returns false.
        public static bool Authenticate(string username, string password)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Query the database for the user with this username,
                // retrieving the stored hash and salt needed to verify the password
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

                        // Read the stored hash and salt from the database
                        byte[] storedHash = (byte[])reader["PasswordHash"];
                        byte[] storedSalt = (byte[])reader["Salt"];

                        // Hash the entered password using the same salt that was
                        // used when the password was originally created
                        byte[] enteredHash = HashPassword(password, storedSalt);

                        // Compare the two hashes in constant time
                        if (CompareHashes(enteredHash, storedHash))
                        {
                            // Match found, store user details in the session
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

        // Inserts a new PaceUser account into the database.
        // Generates a fresh salt and hashes the password before storing,
        // so plain text passwords are never written to the database.
        public static bool CreateUser(string username, string plainTextPassword,
                                      string role, string fullName)
        {
            byte[] salt = GenerateSalt();
            byte[] passwordHash = HashPassword(plainTextPassword, salt);

            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

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
                        int rowsAffected = cmd.ExecuteNonQuery();
                        return rowsAffected == 1;
                    }
                    catch (SqlException ex)
                    {
                        // Error code 2601 and 2627 both mean a duplicate username was entered
                        if (ex.Number == 2601 || ex.Number == 2627)
                            return false;

                        throw;
                    }
                }
            }
        }

        // Returns the role of the currently logged in user from the session.
        public static string GetRole()
        {
            return HttpContext.Current.Session["Role"] != null
                ? HttpContext.Current.Session["Role"].ToString()
                : null;
        }

        // Ends the user's session and logs them out.
        public static void Logout()
        {
            HttpContext.Current.Session.Abandon();
        }
    }
}