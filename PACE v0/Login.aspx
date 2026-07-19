<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="PACE.Login" %>
<!DOCTYPE html>
<html lang="en">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>PACE - Sign In</title>
    <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@300&family=DM+Sans:wght@400;500;600&display=swap" rel="stylesheet" />
    <link runat="server" rel="stylesheet" href="~/Styles/Site.css" />
    <link runat="server" rel="stylesheet" href="~/Styles/Login.css" />
</head>
<body>
    <form id="frmLogin" runat="server">
        <div class="login-card">

            <h1 class="pace-brand">PACE</h1>
            <p class="pace-subtitle">Homework Manager</p>

            <asp:Panel ID="pnlLoginError" runat="server" Visible="false">
                <div class="login-error">Incorrect username or password. Please try again.</div>
            </asp:Panel>

            <div class="form-group">
                <label class="form-label">Username</label>
                <asp:TextBox ID="txtUsername" runat="server" CssClass="field-input" placeholder="Enter your username" MaxLength="50" />
                <asp:Label ID="lblUsernameError" runat="server" CssClass="field-error" Visible="false">Username is required.</asp:Label>
            </div>

            <div class="form-group">
                <label class="form-label">Password</label>
                <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="field-input" placeholder="Enter your password" MaxLength="128" />
                <asp:Label ID="lblPasswordError" runat="server" CssClass="field-error" Visible="false">Password is required.</asp:Label>
            </div>

            <asp:Button ID="btnLogin" runat="server" Text="Sign in" CssClass="login-btn" OnClick="btnLogin_Click" />

        </div>
    </form>
</body>
</html>