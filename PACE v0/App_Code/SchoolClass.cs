using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace PACE
{
    // Represents a class (e.g. "Year 11 Methods") in the PACE system.
    // Each class belongs to one teacher and contains multiple enrolled students.
    public class SchoolClass
    {
        // - Attributes -

        // Unique ID for this class, matches the ClassID primary key in the database
        public int ClassID { get; set; }

        // The display name of the class (e.g. "Year 11 Methods")
        public string ClassName { get; set; }

        // The ID of the teacher who owns this class, links to the Users table
        public int TeacherID { get; set; }

        // - Methods -

        // Retrieves all classes owned by a specific teacher.
        // Used to populate the teacher's sidebar and task creation dropdown.
        public static List<SchoolClass> GetClassesByTeacher(int teacherID)
        {
            List<SchoolClass> classes = new List<SchoolClass>();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT ClassID, ClassName, TeacherID " +
                             "FROM Classes " +
                             "WHERE TeacherID = @TeacherID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TeacherID", teacherID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            // Create a SchoolClass object for each row returned
                            SchoolClass sc = new SchoolClass
                            {
                                ClassID = Convert.ToInt32(reader["ClassID"]),
                                ClassName = reader["ClassName"].ToString(),
                                TeacherID = Convert.ToInt32(reader["TeacherID"])
                            };
                            classes.Add(sc);
                        }
                    }
                }
            }

            return classes;
        }

        // Retrieves all classes a specific student is enrolled in.
        // Used to populate the student's sidebar and main dashboard.
        public static List<SchoolClass> GetClassesByStudent(int studentID)
        {
            List<SchoolClass> classes = new List<SchoolClass>();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // JOIN ClassEnrolments to Classes so we only get classes
                // this specific student is enrolled in
                string sql = "SELECT c.ClassID, c.ClassName, c.TeacherID " +
                             "FROM Classes c " +
                             "INNER JOIN ClassEnrolments ce ON c.ClassID = ce.ClassID " +
                             "WHERE ce.StudentID = @StudentID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@StudentID", studentID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            SchoolClass sc = new SchoolClass
                            {
                                ClassID = Convert.ToInt32(reader["ClassID"]),
                                ClassName = reader["ClassName"].ToString(),
                                TeacherID = Convert.ToInt32(reader["TeacherID"])
                            };
                            classes.Add(sc);
                        }
                    }
                }
            }

            return classes;
        }

        // Retrieves all students enrolled in a specific class.
        // Used by the teacher's completion marking and statistics pages.
        public static List<PaceUser> GetEnrolledStudents(int classID)
        {
            List<PaceUser> students = new List<PaceUser>();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // JOIN ClassEnrolments to Users so we get the full user details
                // for every student enrolled in this class
                string sql = "SELECT u.UserID, u.Username, u.FullName, u.Role " +
                             "FROM Users u " +
                             "INNER JOIN ClassEnrolments ce ON u.UserID = ce.StudentID " +
                             "WHERE ce.ClassID = @ClassID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            PaceUser student = new PaceUser
                            {
                                UserID = Convert.ToInt32(reader["UserID"]),
                                Username = reader["Username"].ToString(),
                                FullName = reader["FullName"].ToString(),
                                Role = reader["Role"].ToString()
                            };
                            students.Add(student);
                        }
                    }
                }
            }

            return students;
        }

        // Checks whether a specific class is owned by a specific teacher.
        // Used as a security check before allowing any teacher action on a class.
        public static bool IsOwnedByTeacher(int classID, int teacherID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT COUNT(*) FROM Classes " +
                             "WHERE ClassID = @ClassID AND TeacherID = @TeacherID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@TeacherID", teacherID);

                    // COUNT(*) returns 1 if the class exists and belongs to this teacher, 0 if not
                    int count = Convert.ToInt32(cmd.ExecuteScalar());
                    return count > 0;
                }
            }
        }
    }
}