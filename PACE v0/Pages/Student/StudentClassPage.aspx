<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="StudentClassPage.aspx.cs" Inherits="PACE.StudentClassPage" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <title>PACE - Class Tasks</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/StudentClassPage.css" />
</head>
<body>
    <form id="frmClassPage" runat="server">

        <aside class="sidebar">
            <div class="sidebar-logo">
                <div class="logo-title">PACE</div>
                <div class="logo-sub">Homework Manager</div>
            </div>
            <nav class="sidebar-nav">
                <div class="nav-section-label">Main</div>
                <a class="nav-item" href="StudentDashboard.aspx"><i class="ti ti-layout-dashboard"></i><span class="nav-item-label">My Dashboard</span></a>
                <div class="nav-section-label">Classes</div>
                <asp:Repeater ID="rptSidebarClasses" runat="server">
                    <ItemTemplate>
                        <a class='<%# GetNavClass(Eval("ClassID")) %>' href='StudentClassPage.aspx?ClassID=<%# Eval("ClassID") %>'>
                            <i class="ti ti-book"></i>
                            <span class="nav-item-label"><%# Eval("ClassName") %></span>
                            <%# Convert.ToInt32(Eval("PendingCount")) > 0
                                ? "<span class='nav-badge" + (Convert.ToInt32(Eval("OverdueCount")) > 0 ? " overdue" : "") + "'>" + Eval("PendingCount") + "</span>"
                                : "" %>
                        </a>
                    </ItemTemplate>
                </asp:Repeater>
            </nav>
            <div class="sidebar-user">
                <div class="user-avatar"><%= GetInitials() %></div>
                <div class="user-info">
                    <div class="user-name"><%= Session["FullName"] %></div>
                    <div class="user-role">Student</div>
                </div>
                <asp:LinkButton ID="btnLogout" runat="server" CssClass="btn-logout" OnClick="btnLogout_Click"><i class="ti ti-logout"></i></asp:LinkButton>
            </div>
        </aside>

        <div class="main">
            <header class="topbar">
                <div class="breadcrumb">
                    <a href="StudentDashboard.aspx">PACE</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <a href="StudentDashboard.aspx">My Dashboard</a>
                    <i class="ti ti-chevron-right sep"></i>
                    <span class="current"><asp:Label ID="lblBreadcrumb" runat="server" /></span>
                </div>
            </header>

            <div class="hero">
                <div class="hero-title"><asp:Label ID="lblHeroTitle" runat="server" /></div>
                <div class="hero-sub">All homework tasks for this class, ordered by due date and priority.</div>
            </div>

            <div class="filter-bar">
                <div class="filter-chips">
                    <button type="button" class="chip active" data-filter="pending"  onclick="setChip(this)">Pending</button>
                    <button type="button" class="chip"        data-filter="complete" onclick="setChip(this)">Completed</button>
                    <button type="button" class="chip"        data-filter="all"      onclick="setChip(this)">All Tasks</button>
                    <button type="button" class="chip"        data-filter="high"     onclick="setChip(this)">High Priority</button>
                    <button type="button" class="chip"        data-filter="overdue"  onclick="setChip(this)">Overdue</button>
                </div>
                <div class="filter-right">
                    <div class="search-wrap">
                        <i class="ti ti-search"></i>
                        <input type="text" id="searchInput" class="search-input" placeholder="Search tasks..." oninput="applyFilters()" />
                    </div>
                    <select id="sortSelect" class="sort-select" onchange="applyFilters()">
                        <option value="due">Sort: Due Date</option>
                        <option value="priority">Sort: Priority</option>
                        <option value="status">Sort: Status</option>
                    </select>
                    <span class="filter-count" id="filterCount"></span>
                </div>
            </div>

            <div class="content">
                <div class="card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#eef8f3;"><i class="ti ti-chart-bar" style="color:#3a9e6e;font-size:17px;"></i></div>
                        <span class="card-header-title">Class Progress</span>
                    </div>
                    <div class="stats-body">
                        <div class="stats-grid">
                            <div class="stat-tile">
                                <div class="stat-value"><asp:Label ID="lblStatTotal" runat="server" /></div>
                                <div class="stat-label">Total Tasks</div>
                            </div>
                            <div class="stat-tile">
                                <div class="stat-value" style="color:var(--green);"><asp:Label ID="lblStatCompleted" runat="server" /></div>
                                <div class="stat-label">Completed</div>
                            </div>
                            <div class="stat-tile">
                                <div class="stat-value" style="color:var(--orange);"><asp:Label ID="lblStatPending" runat="server" /></div>
                                <div class="stat-label">Pending</div>
                            </div>
                        </div>
                        <div>
                            <div class="progress-label-row">
                                <span class="progress-subj">Completion</span>
                                <span class="progress-pct"><%= GetStatsPctDisplay() %></span>
                            </div>
                            <div class="progress-track">
                                <div class="progress-fill <%= GetStatsPctClass() %>" style="width:<%= GetStatsPctWidth() %>%"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card table-card">
                    <div class="card-header">
                        <div class="card-header-icon" style="background:#e8f0fa;"><i class="ti ti-checklist" style="color:#3a5a8c;font-size:17px;"></i></div>
                        <span class="card-header-title">Tasks</span>
                        <span class="card-header-count"><asp:Label ID="lblTaskCount" runat="server" /> tasks</span>
                    </div>

                    <asp:Repeater ID="rptTasks" runat="server">
                        <HeaderTemplate>
                            <table class="task-table">
                                <thead>
                                    <tr><th>Task</th><th>Due Date</th><th>Priority</th><th>Status</th><th>Action</th></tr>
                                </thead>
                                <tbody id="taskTbody">
                        </HeaderTemplate>
                        <ItemTemplate>
                            <tr class="task-row"
                                data-status='<%# Convert.ToBoolean(Eval("MarkedComplete")) ? "complete" : "pending" %>'
                                data-priority='<%# Eval("PriorityLevel") %>'
                                data-title='<%# Eval("Title").ToString().ToLower().Replace("'","") %>'
                                data-due='<%# Convert.ToDateTime(Eval("DueDate")).ToString("yyyy-MM-dd") %>'
                                data-overdue='<%# Convert.ToDateTime(Eval("DueDate")).Date < DateTime.Today ? "1" : "0" %>'>
                                <td>
                                    <div class="task-name"><%# Eval("Title") %></div>
                                    <div class="task-desc"><%# Eval("Description") %></div>
                                </td>
                                <td>
                                    <div class="due-main"><%# Convert.ToDateTime(Eval("DueDate")).ToString("d MMM yyyy") %></div>
                                    <div class="due-urgency <%# GetUrgencyClass(Eval("DueDate")) %>"><%# GetUrgencyText(Eval("DueDate")) %></div>
                                </td>
                                <td><%# GetPriorityBadge(Eval("PriorityLevel")) %></td>
                                <td><%# GetStatusBadge(Eval("MarkedComplete")) %></td>
                                <td><a class="btn-view" href='TaskDetail.aspx?TaskID=<%# Eval("TaskID") %>'><i class="ti ti-eye"></i> View</a></td>
                            </tr>
                        </ItemTemplate>
                        <FooterTemplate></tbody></table></FooterTemplate>
                    </asp:Repeater>

                    <div id="noResults" class="no-results" style="display:none;">No tasks match your search or filter.</div>
                    <asp:Panel ID="pnlNoTasks" runat="server" Visible="false">
                        <div class="empty-state">No tasks assigned to this class yet.</div>
                    </asp:Panel>
                </div>
            </div>
        </div>

    </form>

    <script>
        // Pending is the default view since that is what a student needs to act on first.
        var activeFilter = 'pending';

        /**
         * Marks the clicked filter chip active, deactivates the rest, and re-applies
         * the task filters using the chip's data-filter value.
         * @param {HTMLElement} el - The chip element that was clicked.
         */
        function setChip(el) {
            document.querySelectorAll('.chip').forEach(function(c) { c.classList.remove('active'); });
            el.classList.add('active');
            activeFilter = el.dataset.filter;
            applyFilters();
        }

        /**
         * Filters, searches, sorts, and re-renders the visible task rows based on the
         * active chip, the search box, and the sort dropdown.
         */
        function applyFilters() {
            var search = document.getElementById('searchInput').value.toLowerCase();
            var sortBy = document.getElementById('sortSelect').value;
            var tbody  = document.getElementById('taskTbody');
            if (!tbody) return;

            var rows = Array.from(document.querySelectorAll('.task-row'));
            var visibleCount = 0;

            rows.forEach(function(row) {
                var show = true;
                if (activeFilter === 'pending'  && row.dataset.status !== 'pending')  show = false;
                if (activeFilter === 'complete' && row.dataset.status !== 'complete') show = false;
                if (activeFilter === 'high'     && row.dataset.priority !== '3')      show = false;
                if (activeFilter === 'overdue'  && row.dataset.overdue !== '1')       show = false;
                if (search && !row.dataset.title.includes(search)) show = false;
                row.style.display = show ? '' : 'none';
                if (show) visibleCount++;
            });

            // Re-sort visible rows.
            // "due" is both the dropdown's default option and the page-load state, so it
            // doubles as the default row order. Completion status is sorted first (pending
            // before completed) so a completed task never outranks a pending one by date or
            // priority alone, matching the same rule applied to the initial C# ORDER BY in
            // StudentClassPage.aspx.cs.
            var visible = rows.filter(function(r) { return r.style.display !== 'none'; });
            visible.sort(function(a, b) {
                if (sortBy === 'due') {
                    if (a.dataset.status !== b.dataset.status) return a.dataset.status === 'pending' ? -1 : 1;
                    var dueCompare = a.dataset.due.localeCompare(b.dataset.due);
                    if (dueCompare !== 0) return dueCompare;
                    return parseInt(b.dataset.priority) - parseInt(a.dataset.priority);
                }
                if (sortBy === 'priority') return parseInt(b.dataset.priority) - parseInt(a.dataset.priority);
                if (sortBy === 'status')   return b.dataset.status.localeCompare(a.dataset.status);
                return 0;
            });
            visible.forEach(function(r) { tbody.appendChild(r); });

            var total = rows.length;
            document.getElementById('filterCount').textContent = visibleCount === total
                ? total + ' tasks'
                : visibleCount + ' of ' + total + ' tasks';
            document.getElementById('noResults').style.display = visibleCount === 0 ? 'block' : 'none';
        }

        window.addEventListener('load', applyFilters);
    </script>
</body>
</html>
