
/****** Object:  StoredProcedure [dbo].[USP_SEL_RPTN_DETAIL]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

alter PROCEDURE [dbo].[USP_SEL_ACCESS_RPTN_DETAIL_DSPT_ID]
	
	@pintDsptId INT, 
	@pintPartyRoleID INT, 
	@pintProgramAreaID INT,
	@pintEditPermission INT  OUTPUT,
	@pintHideReportingDetails INT  OUTPUT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].[USP_SEL_ACCESS_RPTN_DETAIL]
 * Author:   c-mahsan
 * Date:     06 APR 2017
 *
 * Purpose/Description: 
 *     Return Edit and View access to the reporting details for the current dispute id for the given party role id 
 *
 * Parameters:
 *     @pintDsptId	Dispute IDENTIFIER 
 *
 * Return:
 *     APP.T_RPTNG_RPTNG_DETAIL, APP.T_DSPT_PETITN, APP.T_UEGF_INDEMNITY_PMT, APP.T_UEGF_RPTNG_WAGE_DETER, APP.T_UEGF_RPTNG_DETER_ISSUE, APP.T_UEGF_RPTNG_INTD_PARTY_RESPBLT
 *
 * Table and Alias Definitions:
 *     T_RPTNG_RPTNG_DETAIL , CLAIM_ID
 *  
 * Called Programs:
 *     NONE
 *
 *********************************************************************/	
 
 SET NOCOUNT ON;
	
	DECLARE	 @intClaimId as INT
	
	SELECT @intClaimId= CLAIM_ID FROM APP.T_DSPT WHERE DSPT_ID = 	@pintDsptId 


	EXEC [dbo].[USP_SEL_ACCESS_RPTN_DETAIL] @intClaimId, 	@pintPartyRoleID , 	@pintProgramAreaID ,@pintEditPermission   OUTPUT,@pintHideReportingDetails  OUTPUT

END