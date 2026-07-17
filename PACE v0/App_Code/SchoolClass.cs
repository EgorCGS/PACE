using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;

namespace PACE
{
    // Represents a class (e.g. "Year 11 Methods") in the PACE system.
    // Each class belongs to one teacher and contains multiple enrolled students.
    public class SchoolClass
    {
        // - Attributes -

        // Unique ID for this class, matches the ClassID primary key in the database.
        // int is used because ClassID is an identity column (SQL int), and every
        // foreign key that references a class (HomeworkTasks.ClassID,
        // ClassEnrolments.ClassID) stores this same int, the C# type has to match
        // so ADO.NET can read/write it, and compare it in WHERE clauses, without
        // any implicit conversion at the call site.
        public int ClassID { get; set; }

        // The display name of the class (e.g. "Year 11 Methods").
        // string maps directly to the NVARCHAR column, NVARCHAR (not VARCHAR)
        // was chosen at the database level so class names are not restricted to
        // ASCII, string in C# is the natural counterpart since it is UTF-16
        // internally and needs no extra encoding/decoding step.
        public string ClassName { get; set; }

        // The ID of the teacher who owns this class, links to the Users table.
        // int for the same identity/foreign key matching reason as ClassID
        // above, TeacherID is compared directly against Users.UserID (also SQL
        // int) in every ownership check and dropdown filter, so no conversion is
        // needed between the C# object and the SQL parameter.
        public int TeacherID { get; set; }

        // - Methods -

        /// <summary>
        /// Retrieves all classes owned by a specific teacher.
        /// </summary>
        /// <param name="teacherID">The teacher whose classes should be retrieved.</param>
        /// <returns>A list of SchoolClass objects owned by this teacher.</returns>
        // Used to populate the teacher's sidebar and task creation dropdown.
        // Returns List<SchoolClass> rather than a DataTable so the calling pages
        // can bind directly to strongly typed objects, the same reasoning
        // applied to PaceTask.GetTasksByClass. More importantly, the
        // WHERE TeacherID = @TeacherID clause is what actually enforces
        // teacher isolation (NFR06, a teacher must only ever see their own
        // classes) at the data layer itself, the query physically cannot
        // return another teacher's class, this matters because relying on the
        // UI alone to hide other teachers' classes would only be a display
        // choice, a teacher who inspected the page's data or replayed the
        // request could still see everything, filtering in the SQL WHERE
        // clause means the restricted rows are never sent to the server-side
        // code in the first place.
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

        /// <summary>
        /// Retrieves all classes a specific student is enrolled in.
        /// </summary>
        /// <param name="studentID">The student whose enrolled classes should be retrieved.</param>
        /// <returns>A list of SchoolClass objects this student is enrolled in.</returns>
        // Used to populate the student's sidebar and main dashboard.
        // A JOIN through ClassEnrolments is required here because a student's
        // classes are not a direct foreign key on the student, unlike TeacherID
        // on SchoolClass, enrolment in the PACE data model is many to many, one
        // student can be in several classes and one class holds several
        // students, so that relationship needs its own linking table
        // (ClassEnrolments) rather than a single column on either side. The
        // ClassEnrolments table itself has its own EnrolmentID primary key and
        // a unique constraint on (StudentID, ClassID), so this INNER JOIN can
        // never return duplicate rows for the same student/class pairing, that
        // uniqueness is enforced at the schema level, not something this query
        // has to defend against with DISTINCT or similar.
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

        /// <summary>
        /// Retrieves all students enrolled in a specific class.
        /// </summary>
        /// <param name="classID">The class to retrieve enrolled students for.</param>
        /// <returns>A list of PaceUser objects representing the enrolled students.</returns>
        // Used by the teacher's completion marking and statistics pages.
        // Returns List<PaceUser> rather than a DataTable, keeping with the same
        // typed-object pattern used by GetClassesByTeacher/GetClassesByStudent
        // above and by PaceTask elsewhere in the app, callers work with real
        // PaceUser properties (UserID, FullName, Role) instead of pulling
        // values out of a DataTable by string column name, which would be an
        // inconsistent second style of data access sitting alongside the typed
        // objects used everywhere else. This is also the exact list
        // MarkCompletions.aspx.cs renders as its roster of tickable students,
        // so the shape returned here has to already be the PaceUser type that
        // page's markup binds to, not a raw result set it would need to
        // convert first.
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

        /// <summary>
        /// Checks whether a specific class is owned by a specific teacher.
        /// </summary>
        /// <param name="classID">The class to check.</param>
        /// <param name="teacherID">The teacher to check ownership against.</param>
        /// <returns>True if the class exists and belongs to this teacher, false otherwise.</returns>
        // Used as a security check before allowing any teacher action on a class.
        // This exists as its own single reusable method, rather than the same
        // ownership SQL being written inline inside CreateTask, ManageTasks,
        // MarkCompletions and TeacherClassPage separately, because ownership
        // verification is security critical, if even one of those four call
        // sites got the check wrong or forgot it entirely, a teacher could
        // supply someone else's ClassID (by editing a hidden form field, a
        // query string, or a posted value) and edit, delete, or mark
        // completions on a class that is not theirs. Centralising the check in
        // one method means there is exactly one place where the ownership rule
        // is expressed and can be verified as correct, every calling page just
        // calls IsOwnedByTeacher(classID, teacherID) before performing its
        // write and trusts the same, single, tested code path, instead of four
        // separate copies of the same logic that could quietly drift apart or
        // be missed on a future page.
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
