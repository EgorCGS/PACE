<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Setup.aspx.cs" Inherits="PACE.Setup" %>

<!DOCTYPE html>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>PACE Setup</title>
</head>
<body>
    <form id="form1" runat="server">
        <h2>PACE Database Setup</h2>
        <asp:Button ID="btnSetup" runat="server" Text="Create Test Accounts" OnClick="btnSetup_Click" />
        <br /><br />
        <asp:Label ID="lblResult" runat="server" />
    </form>
</body>
</html>