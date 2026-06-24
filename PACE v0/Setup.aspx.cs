using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.UI;

namespace PACE
{
    public partial class Setup : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void btnSetup_Click(object sender, EventArgs e)
        {
            string result = "";

            // Create user accounts
            result += PaceUser.CreateUser("egor", "admin123", "Teacher", "Egor Ognev")
                ? "Teacher created.<br />" : "Teacher already exists.<br />";
            result += PaceUser.CreateUser("felix", "student123", "Student", "Felix")
                ? "Felix created.<br />" : "Felix already exists.<br />";
            result += PaceUser.CreateUser("neil", "student123", "Student", "Neil")
                ? "Neil created.<br />" : "Neil already exists.<br />";
            result += PaceUser.CreateUser("bucknell", "student123", "Student", "Bucknell")
                ? "Bucknell created.<br />" : "Bucknell already exists.<br />";

            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                // Get the teacher's UserID
                int teacherID = 0;
                using (SqlCommand cmd = new SqlCommand("SELECT UserID FROM Users WHERE Username = 'egor'", conn))
                {
                    object res = cmd.ExecuteScalar();
                    if (res != null) teacherID = Convert.ToInt32(res);
                }

                if (teacherID == 0)
                {
                    lblResult.Text = result + "Could not find teacher account. Run setup again.";
                    return;
                }

                // Create class if it doesn't exist
                int classID = 0;
                using (SqlCommand cmd = new SqlCommand("SELECT ClassID FROM Classes WHERE ClassName = 'Year 11 Methods'", conn))
                {
                    object res = cmd.ExecuteScalar();
                    if (res != null)
                    {
                        classID = Convert.ToInt32(res);
                        result += "Class already exists.<br />";
                    }
                }

                if (classID == 0)
                {
                    using (SqlCommand cmd = new SqlCommand(
                        "INSERT INTO Classes (ClassName, TeacherID) VALUES ('Year 11 Methods', @TeacherID); SELECT SCOPE_IDENTITY();", conn))
                    {
                        cmd.Parameters.AddWithValue("@TeacherID", teacherID);
                        classID = Convert.ToInt32(cmd.ExecuteScalar());
                        result += "Class created.<br />";
                    }
                }

                // Enrol each student
                string[] students = { "felix", "neil", "bucknell" };
                foreach (string username in students)
                {
                    int studentID = 0;
                    using (SqlCommand cmd = new SqlCommand("SELECT UserID FROM Users WHERE Username = @u", conn))
                    {
                        cmd.Parameters.AddWithValue("@u", username);
                        object res = cmd.ExecuteScalar();
                        if (res != null) studentID = Convert.ToInt32(res);
                    }

                    if (studentID == 0) continue;

                    // Check if already enrolled
                    int enrolCount = 0;
                    using (SqlCommand cmd = new SqlCommand(
                        "SELECT COUNT(*) FROM ClassEnrolments WHERE StudentID = @s AND ClassID = @c", conn))
                    {
                        cmd.Parameters.AddWithValue("@s", studentID);
                        cmd.Parameters.AddWithValue("@c", classID);
                        enrolCount = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (enrolCount == 0)
                    {
                        using (SqlCommand cmd = new SqlCommand(
                            "INSERT INTO ClassEnrolments (StudentID, ClassID) VALUES (@s, @c)", conn))
                        {
                            cmd.Parameters.AddWithValue("@s", studentID);
                            cmd.Parameters.AddWithValue("@c", classID);
                            cmd.ExecuteNonQuery();
                            result += username + " enrolled.<br />";
                        }
                    }
                    else
                    {
                        result += username + " already enrolled.<br />";
                    }
                }

                // Insert tasks if none exist for this class
                int taskCount = 0;
                using (SqlCommand cmd = new SqlCommand("SELECT COUNT(*) FROM HomeworkTasks WHERE ClassID = @c", conn))
                {
                    cmd.Parameters.AddWithValue("@c", classID);
                    taskCount = Convert.ToInt32(cmd.ExecuteScalar());
                }

                if (taskCount == 0)
                {
                    string insertTask = "INSERT INTO HomeworkTasks (ClassID, Title, Subject, Description, DueDate, PriorityLevel, CreatedDate) " +
                                       "VALUES (@c, @title, @subj, @desc, @due, @pri, GETDATE())";

                    object[,] tasks = {
                        { "Exercises 4A - Derivatives", "Mathematics", "Complete odd-numbered questions from Exercise 4A. Show full working.", DateTime.Today.AddDays(2), 3 },
                        { "Revision Practice Test",     "Mathematics", "Complete all sections of the Unit 2 practice test under timed conditions.", DateTime.Today.AddDays(7), 2 },
                        { "Chapter 3 Reading",          "Mathematics", "Read Chapter 3 on integration and annotate key definitions.", DateTime.Today.AddDays(14), 1 }
                    };

                    for (int i = 0; i < tasks.GetLength(0); i++)
                    {
                        using (SqlCommand cmd = new SqlCommand(insertTask, conn))
                        {
                            cmd.Parameters.AddWithValue("@c", classID);
                            cmd.Parameters.AddWithValue("@title", tasks[i, 0]);
                            cmd.Parameters.AddWithValue("@subj", tasks[i, 1]);
                            cmd.Parameters.AddWithValue("@desc", tasks[i, 2]);
                            cmd.Parameters.AddWithValue("@due", tasks[i, 3]);
                            cmd.Parameters.AddWithValue("@pri", tasks[i, 4]);
                            cmd.ExecuteNonQuery();
                        }
                    }
                    result += "3 tasks created.<br />";
                }
                else
                {
                    result += "Tasks already exist.<br />";
                }
            }

            lblResult.Text = result;
        }
    }
}