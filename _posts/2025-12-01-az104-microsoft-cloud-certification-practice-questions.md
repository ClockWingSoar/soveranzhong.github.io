---
layout: post
title: AZ104 微软云认证备考题库
categories: [Cloud, Azure, Certification]
description: 包含AZ104微软Azure管理员认证考试的备考题目、解析和答案，帮助考生系统复习和准备考试。
keywords: AZ104, Azure, 微软云认证, 管理员认证, 备考题库, 考试准备
mermaid: true
sequence: false
flow: true
mathjax: false
mindmap: false
mindmap2: false
---

# AZ104 微软云认证备考题库

## SCQA结构

### 情境(Situation)
在当前云计算快速发展的时代，Azure作为全球领先的云平台之一，其管理员认证(AZ104)已成为DevOps、SRE和云工程师必备的专业资质。持有AZ104认证不仅能证明个人的Azure技术能力，还能提升职业竞争力和薪资水平。

### 冲突(Conflict)
然而，AZ104考试涵盖内容广泛，包括Azure资源管理、安全、网络、存储等多个领域，考生往往面临知识点分散、难以系统复习的挑战。传统的学习方式效率低下，缺乏针对性的练习和反馈。

### 问题(Question)
如何高效备考AZ104认证考试？如何系统掌握考试知识点并通过大量练习巩固记忆？

### 答案(Answer)
本博客提供一份结构化的AZ104备考题库，包含精选题目、详细解析和正确答案，帮助考生系统复习、针对性练习，提高备考效率和考试通过率。

## 题库结构

本题库按照AZ104考试的主要知识点进行分类，便于考生根据学习进度选择相应部分进行练习。每个题目包含题目描述、选项、正确答案和详细解析。

## 题目模板

### 题目分类
- **资源管理**
- **安全与合规**
- **网络**
- **存储**
- **计算**
- **监控与故障排除**

### 题目格式示例

1. You want to associate each VM with its respective department  -- **Assign tags to the virtual machines.**

2. You access the multi-factor authentication page to alter the user settings -- **No**

3. You access the Azure portal to alter the session control of the Azure AD conditional access policy. -- **No**

4. You access the Azure portal to alter the grant control of the Azure AD conditional access policy. -- **Yes**

5. You are required to implement a custom deployment that includes adding a particular trusted root certification authority (CA).
  Which of the following should you use to create the virtual machine?  -- **The az vm create command.**

6. You reconfigure the existing usage model via the Azure portal -- **No**

7. You reconfigure the existing usage model via the Azure CLI -- **No**

8. You create a new Multi-Factor Authentication provider with a backup from the existing Multi-Factor Authentication provider data  -- **No**

9. You run the Start-ADSyncSyncCycle -PolicyType Initial PowerShell cmdlet. -- **No**

10. You use Active Directory Sites and Services to force replication of the Global Catalog on a domain controller. -- **No**

11. You restart the NetLogon service on a domain controller. -- **No**

12. Which of the following Azure stored redundancy options should you recommend -- **Read-only geo-redundant storage**

13. You want to review the ARM template that was used by Jon Ross. You access the Virtual Machine blade -- **No**

14. You want to review the ARM template that was used by Jon Ross. You access the Resource Group blade - **Yes**

15. You want to review the ARM template that was used by Jon Ross. You access the Container blade.  -- **No**

16. You try to resize one of the VMs, which returns an allocation failure message.It is imperative that the VM is resized -- **You should stop all three VMs.**

17. You need to make sure that your strategy allows for the virtual machines to be offline for the least amount of time possible.
    Which of the following is the action you should take FIRST?  -- **Detach the data disk.**

18. You are required to make sure that the ARM template you configure allows for as many VMs as possible to remain accessible
    in the event of fabric failure or maintenance.
    Which of the following is the value that you should configure for the platformFaultDomainCount property? -- **Max Value**

19. You are required to make sure that the ARM template you configure allows for as many VMs as possible to remain accessible
    in the event of fabric failure or maintenance.
    Which of the following is the value that you should configure for the platformUpdateDomainCount property?  -- **20**

20. You need to make sure that the password cannot be stored in plain text.
    You are preparing to create the necessary components to achieve your goal.
    Which of the following should you create to achieve your goal?  -- **An Azure Key Vault, An Access key**

21. You have created some PowerShell scripts to automate the configuration of newly created VMs. You plan to create several new
    VMs.
    You need a solution that ensures the scripts are run on the new VMs -- **Configure a SetupComplete.cmd batch file in the %windir%\setup\scripts directory.**

22. You configure a reference VM in the on-premise virtual environment. You then generalize the VM to create an image.
    You need to upload the image to Azure to ensure that it is available for selection when you create the new Azure VMs.
    Which PowerShell cmdlets should you use?  -- **Add-AzVhd**

23. Your company has an Azure subscription that includes a number of Azure virtual machines (VMs), which are all part of the
    same virtual network.
    Your company also has an on-premises Hyper-V server that hosts a VM, named VM1, which must be replicated to Azure -- **Hyper-V site, Azure Recovery Services Vault, Replication policy**

24. You choose the Allow gateway transit setting on VirtualNetworkA. -- **No**

25. You choose the Allow gateway transit setting on VirtualNetworkB. -- **No**

26. You download and re-install the VPN client configuration package on the Windows 10 workstation. -- **Yes**

27. The company has users that work remotely. The remote workers require access to the VMs on VNet1.
    You need to provide access for the remote workers.  -- **Configure a Point-to-Site (P2S) VPN.**

28. You create an HTTP health probe on port 1433. -- **No**

29. You set Session persistence to Client IP  -- **No**

30. You enable Floating IP.  -- **Yes**

31. You need to configure the two VMs with static internal IP addresses. --   **Modify the VM properties in the Azure Management Portal**

32. Which of the following is the least amount of network interfaces needed for this configuration? -- **5**

33. Which of the following is the least amount of security groups needed for this configuration? -- **1**

34. When the VM becomes infected with data encrypting ransomware, you decide to recover the VM's files. -- **You can recover the files to any VM within the company's subscription.**

35. When the VM becomes infected with data encrypting ransomware, you are required to restore the VM. -- **You should restore the VM to a new Azure VM**

36. You need to find the cause of the performance issues pertaining to metrics on the Azure infrastructure. -- **Azure Monitor**

37. You want to use Azure Backup to schedule a backup of your company's virtual machines (VMs) to the Recovery Services vault.
    Which of the following VMs can you back up?  -- **ABCDE**

    ```
    A. VMs that run Windows 10. 
    B. VMs that run Windows Server 2012 or higher. 
    C. VMs that have NOT been shut down.
    D. VMs that run Debian 8.2+.
    E. VMs that have been shut down.
    ```

38. You create a PowerShell script that runs the New-AzureADUser cmdlet for each user -- **No**

39. From Azure AD in the Azure portal, you use the Bulk create user operation. -- **No**

40. You create a PowerShell script that runs the New-AzureADMSInvitation cmdlet for each external user.  -- **Yes**

41. You need to ensure that an administrator named Admin1 can manage LB1 and LB2. The solution must follow the principle of
    least privilege.
    Which role should you assign to Admin1 for each task? -- **Box 1. Network Contributor on RG1 , Box 2. Network Contributor on RG1**

42. An administrator reports that she is unable to grant access to AKS1 to the users in contoso.com.
    You need to ensure that access to AKS1 can be granted to the contoso.com users. -- **From contoso.com, create an OAuth 2.0 authorization endpoint.**

43.  You need to create groups for the users. The solution must ensure that the groups are deleted automatically after 180 days. -- **a Microsoft 365 group that uses the Assigned membership type, a Microsoft 365 group that uses the Dynamic User membership type**

44. User3 can perform an access review of User1 = No
    User3 can perform an access review of UserA = No
    User3 can perform an access review of UserB = No

45. ![image-20251211153923254](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211153923254.png)

46. What is the effect of the policy? -- **You can create Azure SQL servers in ContosoRG1 only**

47. VNET1 will only have Department: D1 tag & VNET 2 will only have Label : Value1 tag![image-20251211154116336](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211154116336.png)

48. You need to identify which resources can be moved to AZPT2 -- **VM1, storage1, VNET1, VM1Managed, and RVAULT1**

49. You need to ensure that Admin1 can deploy the Marketplace resource successfully -- **From Azure PowerShell, run the Set-AzMarketplaceTerms cmdlet**

50. You need to assign the User administrator administrative role to AdminUser1  -- **From the Directory role blade, modify the directory role**

51. You need to ensure that 10 users can use all the Azure AD Premium features -- **From the Licenses blade of Azure AD, assign a license**

52. You need to ensure that an alert is set in Service Manager when the amount of available memory on VM1 is below 10 percent -- **Deploy the IT Service Management Connector (ITSM)**

53. You need to add a user named admin1@contoso.com as an administrator on all the computers that will be joined to the Azure AD domain -- **Device settings from the Devices blade**

54. User1 can add Device2 to Group1: No
    User2 can add Device1 to Group1: Yes
    User2 can add Device2 to Group2: No

55. When the project is complete, you attempt to delete RG26 from the Azure portal. The deletion fails.
    You need to delete RG26.  -- **Stop the backup of SQLDB01**

56. You have an Azure subscription named Subscription1 that contains a virtual network named VNet1. VNet1 is in a resource
    group named RG1.
    Subscription1 has a user named User1. User1 has the following roles:
    ? Reader
    ? Security Admin
    ? Security Reader

    You need to ensure that User1 can assign the Reader role for VNet1 to other users.  -- **Assign User1 the User Access Administrator role for VNet1.**

57. You need to ensure that Azure can verify the domain name, Which type of DNS record should you create?  -- **MX**

58. On Subscription1, you assign the DevTest Labs User role to the Developers group  -- **No**

59. On Subscription1, you assign the Logic App Operator role to the Developers group -- **No**

60. On Dev, you assign the Contributor role to the Developers group.  -- **YES**

61. You need to send a report to the finance department. The report must detail the costs for each department.
    Which three actions should you perform in sequence? 

    ```
    Box 1: Assign a tag to each resource
    Box 2: From the Cost analysis blade, filter the view by tag
    Box 3: Download the usage report
    ```

62. You have an Azure subscription named Subscription1 that contains an Azure Log Analytics workspace named Workspace1， You need to view the error events from a table named Event  -- **search in (Event) "error"**

63. ![image-20251211163521396](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211163521396.png)

64. RG1 has a web app named WebApp1. WebApp1 is located in West Europe.
    You move WebApp1 to RG2.
    What is the effect of the move?  -- **The App Service plan for WebApp1 remains in West Europe. Policy2 applies to WebApp1**
65. ![image-20251211163654448](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211163654448.png)

66. You need to ensure that the connections to App1 are spread across all the virtual machines -- **an internal load balancer，an Azure Application Gateway**
67. You need to quickly identify underutilized virtual machines that can have their service tier changed to a less expensive
    offering.
    Which blade should you use?  -- **Advisor**
68. The Answer is correct .
    - Select Users & Groups : Where you have to choose all users.
    - Select Cloud apps or actions: to specify the Azure portal
    - Grant: to grant the MFA![image-20251211163915475](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211163915475.png)



69. You need to ensure that Admin1 can invite the external partner to sign in to the Azure AD tenant -- **From the Users settings blade, modify the External collaboration settings**
70. You need to ensure that User1 can assign a policy to the tenant root management group -- **Assign the Global administrator role to User1, and then instruct User1 to configure access management for Azure resources**
71. User 1: Group 1 only
    User 2: Group 1 & 2
72. **Box 1:User1 and User3 only**
    You must use Windows Server Active Directory to update the identity, contact info, or job info for users whose source of authority is Windows Server Active Directory.
    **Box 2: User1, User2, and User3**
    Usage location is an Azure property that can only be modified from Azure AD (for all users including Windows Server AD users synced via Azure AD Connect)
73. You assign the Network Contributor role at the subscription level to Admin1  -- **Yes**
74. You assign the Owner role at the subscription level to Admin1  -- **Yes**
75. You assign the Reader role at the subscription level to Admin1  -- **No**
76. Which role-based access control (RBAC) role should you assign to User1 -- **Contributor**
77. ![image-20251211171152740](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211171152740.png)

78. You need to ensure that a service running on VM1 can manage the resources in RG1 by using the identity of VM1.
    What should you do first? -- **From the Azure portal, modify the Managed Identity settings of VM1**
79. You need to delete TestRG -- **Remove the resource lock from VNET1 and delete all data in Vault1**
80. You need to delegate a subdomain named research.adatum.com to a different DNS server in Azure --  **Create an NS record named research in the adatum.com zone**
81. Add the custom domain name to your directory，Add a DNS entry for the domain name at the domain name registrar，Verify the custom domain name in Azure AD![image-20251211171449753](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211171449753.png)



82. You need to ensure that records created in the contoso.com zone are resolvable from the internet -- **Modify the NS records in the DNS domain registrar**
83. ![image-20251211171628950](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211171628950.png)



84. ![image-20251211171656690](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211171656690.png)

Box 1: User1 and User3 only.
User1: The Owner Role lets you manage everything, including access to resources.
User3: The Network Contributor role lets you manage networks, including creating subnets.
Box 2: User1 only.
The Security Admin role: In Security Center only: Can view security policies, view security states, edit security policies, view
alerts and recommendations, dismiss alerts and recommendations



85. ![image-20251211171743103](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211171743103.png)

Box 1: Sub1, RG1, and VM1 only -
You can lock a subscription, resource group, or resource to prevent other users in your organization from accidentally
deleting or modifying critical resources.
Box 2: Sub1, RG1, and VM1 only -
You apply tags to your Azure resources, resource groups, and subscriptions



86. You need to create and upload a file for the bulk delete  -- **The user principal name of each user only**
87. ![image-20251211171847754](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211171847754.png)

Box 1: No -
The Azure Policy will add Tag4 to RG1.
Box 2: No -
Tags applied to the resource group or subscription aren't inherited by the resources although you can enable inheritance
with Azure Policy. Storage1 has Tag3:
Value1 and the Azure Policy will add Tag4.
Box 3: No -
Tags applied to the resource group or subscription aren't inherited by the resources so VNET1 does not have Tag2.
VNET1 has Tag3:value2. VNET1 is excluded from the Azure Policy so Tag4 will not be added to VNET1



88. You assign the Traffic Manager Contributor role at the subscription level to Admin1 -- **No**
89. You need to grant user management permissions to a local administrator in each office  -- **administrative units**
90. you assign the Logic App Contributor role to the Developers group  -- **YES**
91. ![image-20251211172137503](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211172137503.png)



1) User1 can "assign access to other users for" LB1.
2) User1 can "delete a virtual machine from" the resource group



92.  You have an Azure subscription named Subscription1 that contains a virtual network named VNet1. VNet1 is in a resource
    group named RG1.
    Subscription1 has a user named User1. User1 has the following roles:
    ? Reader
    ? Security Admin
    ? Security Reader
    You need to ensure that User1 can assign the Reader role for VNet1 to other users.
    What should you do?

    -- **Assign User1 the Owner role for VNet1**  or **Assign User1 the User Access Administrator role for VNet1** or **Assign User1 the Access Administrator role for VNet1**

93. ![image-20251211172957561](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211172957561.png)

correct answer is **dataActions** and **assignableScopes**

94. You need to grant Group1 the Storage File Data SMB Share Elevated Contributor role for share1  -- **Enable Active Directory Domain Service (AD DS) authentication for storage1**
95. You need to ensure that Group1 can manage role assignments for the existing subscriptions and the planned subscriptions  -- **Assign Group1 the User Access Administrator role for the root management group**
96. ![image-20251211173156538](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211173156538.png)

97.  You need to create new user accounts in external.contoso.onmicrosoft.com  ，You instruct User2 to create the user accounts   -- **No**
98. You need to create new user accounts in external.contoso.onmicrosoft.com.
    Solution: You instruct User4 to create the user accounts   -- **No**
99. You need to create new user accounts in external.contoso.onmicrosoft.com.
    Solution: You instruct User3 to create the user accounts.  -- **No**
100. You need to ensure that you can apply the custom role to any resource group in Sub1 and Sub2. The solution must minimize
     administrative effort  -- **Select the custom role and add Sub1 and Sub2 to the assignable scopes. Remove RG1 from the assignable scopes.**
101. ![image-20251211173843484](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211173843484.png)



**Upload blob data to storageacct1234， View blob data in storageacct1234**



102.  You need to ensure that the developers of App1 can use their Azure AD credentials to deploy content to App1  -- **Assign the Website Contributor role to the developers**
103. From Azure AD in the Azure portal, you use the Bulk invite users operation  -- **No**
104. ![image-20251211174040759](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211174040759.png)

Role3: Role1 and built-in Azure subscription roles only
Role4: Role2 only



105. ![image-20251211174123308](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211174123308.png)





Answer is correct.
"Reader and Data Access":
"Lets you view everything but will not let you delete or create a storage account or contained resource. It will also allow
read/write access to all data contained in a storage account via access to storage account keys



106. You need to ensure that the virtual machines can access Vault1  -- **a service tag**

107. Which users are assigned the Azure Active Directory Premium Plan 2 license -- **User1 and User4 only**
108. ![image-20251211174301764](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211174301764.png)





N - Because not Connected
Y - Because when it expires it is removed from the group. Proof to follow
Y - Because..math



109. ![image-20251211174353704](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211174353704.png)





110. You need to ensure that all the traffic from VM1 to storage1 travels across the Microsoft backbone network.  -- **private endpoints** or **service endpoints**

111. ![image-20251211174617798](2025-12-01-az104-microsoft-cloud-certification-practice-questions.assets/image-20251211174617798.png)

Correct Answers. YES, No, Yes
(YES)User1 can create a storage account in RG1, since User1 has Storage Account Contribute Role inherited from Resource
Group.
(NO) User1 can modify the DNS settings of networkinterface1, since it requires Network Contribute role referring to the following
link.
https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-network-interface?tabs=network-interface-
portal#permissions
(YES) User1 can create an inbound security rule to filter inbound traffic to networkinterface1, since User1 has Contributor role for
NSG1



112. 



## 备考建议

1. **系统学习**：按照题库分类，逐一学习每个知识点
2. **反复练习**：多做题目，加深对知识点的理解和记忆
3. **错题分析**：重点关注错误题目，理解错误原因
4. **实践操作**：结合Azure Portal或Azure CLI进行实际操作练习
5. **模拟考试**：使用官方或第三方模拟考试工具进行模拟测试

## 资源推荐

- [官方AZ104考试指南](https://learn.microsoft.com/en-us/certifications/exams/az-104)
- [Azure学习路径](https://learn.microsoft.com/en-us/training/paths/az-104-administrator/)
- [Microsoft Learn](https://learn.microsoft.com/en-us/azure/)

## 结语

本题库将持续更新和完善，欢迎大家在评论区提出建议和补充。祝各位考生备考顺利，成功通过AZ104认证考试！

---

**题目添加区域**：

在这里添加您的AZ104考试题目，按照上面的题目格式示例进行组织。

---

**题目添加区域结束**

---

## 更新记录

- 2025-12-01：初始创建题库模板
- [日期]：[更新内容]