using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace PACE
{
    // Represents a single homework task in the PACE system.
    // Tasks are created by teachers and viewed by students.
    public class PaceTask
    {
        // - Attributes -

        // Unique ID for this task, matches the TaskID primary key in the database
        public int TaskID { get; set; }

        // The ID of the class this task belongs to, links to the Classes table
        public int ClassID { get; set; }

        // The short title of the task (e.g. "Exercises 4A, Derivatives")
        public string Title { get; set; }

        // The subject this task belongs to (e.g. "Mathematics")
        public string Subject { get; set; }

        // The full description of the task, visible to students
        public string Description { get; set; }

        // The date this task is due
        public DateTime DueDate { get; set; }

        // The priority level of the task, stored as an integer (1=Low, 2=Medium, 3=High)
        public int PriorityLevel { get; set; }

        // The date and time this task was created, set automatically on insert
        public DateTime CreatedDate { get; set; }

        // - Methods -

        // Converts the integer priority level to a readable label.
        // Returns "High", "Medium", or "Low" based on the stored integer value.
        public string GetPriorityLabel()
        {
            if (PriorityLevel == 3) return "High";
            if (PriorityLevel == 2) return "Medium";
            return "Low";
        }

        // Returns the CSS class name for the priority badge colour.
        // These class names match the colour scheme defined in the mockups.
        public string GetPriorityBadgeColour()
        {
            if (PriorityLevel == 3) return "badge-high";
            if (PriorityLevel == 2) return "badge-medium";
            return "badge-low";
        }

        // Validates all input fields before a task is created or edited.
        // Returns true if all fields are valid, false if any check fails.
        public static bool ValidateInputs(string title, string subject, string description, string dueDateStr, string priorityStr)
        {
            // Existence check, no field may be empty
            if (string.IsNullOrWhiteSpace(title) ||
                string.IsNullOrWhiteSpace(subject) ||
                string.IsNullOrWhiteSpace(description) ||
                string.IsNullOrWhiteSpace(dueDateStr) ||
                string.IsNullOrWhiteSpace(priorityStr))
            {
                return false;
            }

            // Type check, due date must be a real valid date
            DateTime parsedDate;
            if (!DateTime.TryParse(dueDateStr, out parsedDate))
            {
                return false;
            }

            // Range check, priority must be 1, 2, or 3
            int priority;
            if (!int.TryParse(priorityStr, out priority) || priority < 1 || priority > 3)
            {
                return false;
            }

            return true;
        }

        // Inserts a new homework task into the database.
        // Returns the ID of the newly created task.
        public static int Create(int classID, string title, string subject,
                                 string description, DateTime dueDate, int priorityLevel)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "INSERT INTO HomeworkTasks (ClassID, Title, Subject, Description, DueDate, PriorityLevel, CreatedDate) " +
                             "VALUES (@ClassID, @Title, @Subject, @Description, @DueDate, @PriorityLevel, @CreatedDate); " +
                             "SELECT SCOPE_IDENTITY();";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);
                    cmd.Parameters.AddWithValue("@Title", title);
                    cmd.Parameters.AddWithValue("@Subject", subject);
                    cmd.Parameters.AddWithValue("@Description", description);
                    cmd.Parameters.AddWithValue("@DueDate", dueDate);
                    cmd.Parameters.AddWithValue("@PriorityLevel", priorityLevel);
                    cmd.Parameters.AddWithValue("@CreatedDate", DateTime.Now);

                    // SCOPE_IDENTITY() returns the ID of the row just inserted
                    return Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
        }

        // Updates an existing homework task in the database.
        // Returns true if the update was successful.
        public static bool Edit(int taskID, string title, string subject,
                                string description, DateTime dueDate, int priorityLevel)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "UPDATE HomeworkTasks " +
                             "SET Title = @Title, Subject = @Subject, Description = @Description, " +
                             "DueDate = @DueDate, PriorityLevel = @PriorityLevel " +
                             "WHERE TaskID = @TaskID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);
                    cmd.Parameters.AddWithValue("@Title", title);
                    cmd.Parameters.AddWithValue("@Subject", subject);
                    cmd.Parameters.AddWithValue("@Description", description);
                    cmd.Parameters.AddWithValue("@DueDate", dueDate);
                    cmd.Parameters.AddWithValue("@PriorityLevel", priorityLevel);

                    // ExecuteNonQuery returns the number of rows affected
                    int rowsAffected = cmd.ExecuteNonQuery();
                    return rowsAffected > 0;
                }
            }
        }

        // Permanently deletes a homework task from the database.
        // Returns true if the deletion was successful.
        public static bool Delete(int taskID)
        {
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "DELETE FROM HomeworkTasks WHERE TaskID = @TaskID";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@TaskID", taskID);

                    int rowsAffected = cmd.ExecuteNonQuery();
                    return rowsAffected > 0;
                }
            }
        }

        // Retrieves all tasks assigned to a specific class, ordered by due date
        // then by priority level (highest priority first).
        public static List<PaceTask> GetTasksByClass(int classID)
        {
            List<PaceTask> tasks = new List<PaceTask>();
            string connStr = ConfigurationManager.ConnectionStrings["PACEConnectionString"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                string sql = "SELECT TaskID, ClassID, Title, Subject, Description, DueDate, PriorityLevel, CreatedDate " +
                             "FROM HomeworkTasks " +
                             "WHERE ClassID = @ClassID " +
                             "ORDER BY DueDate ASC, PriorityLevel DESC";

                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    cmd.Parameters.AddWithValue("@ClassID", classID);

                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            // Create a PaceTask object for each row returned
                            PaceTask task = new PaceTask
                            {
                                TaskID = Convert.ToInt32(reader["TaskID"]),
                                ClassID = Convert.ToInt32(reader["ClassID"]),
                                Title = reader["Title"].ToString(),
                                Subject = reader["Subject"].ToString(),
                                Description = reader["Description"].ToString(),
                                DueDate = Convert.ToDateTime(reader["DueDate"]),
                                PriorityLevel = Convert.ToInt32(reader["PriorityLevel"]),
                                CreatedDate = Convert.ToDateTime(reader["CreatedDate"])
                            };
                            tasks.Add(task);
                        }
                    }
                }
            }

            return tasks;
        }
    }
}