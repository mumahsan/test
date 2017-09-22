


ALTER PROCEDURE [dbo].[USP_UPD_UEGF_CLAIM_STATUS_APPEAL]
	 @pintClaimId INT
	 ,@pintAppealCaseId INT	
	,@pintStaffId INT
	,@pintOfficeId INT
AS

/*********************************************************************
* Name:     dbo.[USP_UPD_UEGF_CLAIM_STATUS_EX]
* Author:   Rizwan Mohammed
* Date:     07/18/2017
*
* Purpose/Description:
*  Updates UEGF Claim status and take reporting snapshot
*		
*		
*
* Parameters:
* 
*	
* Return:
* 
*               
* Table and Alias Definitions: 
*
* 		
*
* Called Programs:
*     None
*
****************************************************************************************************************************************/
BEGIN

--CHECK IF THIS IS UEGF CLAIM 
DECLARE @pint550DisputeId INT, @pint550DisputeDispTypeId INT, @pint550OponDispTypeId INT, @intUEGFClaimStatus INT

	IF EXISTS (SELECT tc.CLAIM_ID FROM APP.T_CLAIM tc
					WHERE tc.CLAIM_CAT_TYPE_ID = 7 -- 7 = UEGF
					AND tc.CLAIM_ID = @pintClaimId)
	BEGIN
	
		-- THIS IS UEGF CLAIM 
		UPDATE APP.T_UEGF_RPTNG_DETAIL SET WCAB_APPEAL_FLAG = 1 WHERE CLAIM_ID = @pintClaimId

		--SELECT TOP 1 @pint550DisputeId = TDP.DSPT_ID ,@pint550DisputeDispTypeId = TDP.DSPT_DISPN_TYPE_ID,
		--		@pint550OponDispTypeId = TDP.OPON_DISPN_TYPE_ID
		--FROM APP.T_DSPT_PETITN TDP
		--INNER JOIN APP.T_DSPT_PETITN_LIBC550 TDPL ON TDP.DSPT_PETITN_ID = TDPL.DSPT_PETITN_ID
		--WHERE TDP.CLAIM_ID = @pintClaimId  
		--ORDER BY TDPL.DSPT_PETITN_ID

		----if appeal is filed on 550 dispute then uegf status is open in litigation
		--IF EXISTS ( SELECT * FROM APP.T_APPEAL_CASE WHERE APPEAL_CASE_ID = @pintAppealCaseId AND DSPT_ID = @pint550DisputeId)
		--BEGIN 
		--		-- APPEAL FILE ON 550 DISPUTE
		--	SET @intUEGFClaimStatus = 2 
		--END 
		--ELSE
		--BEGIN 
		--	--SELECT * FROM LKP.T_DISPN_TYPE
		--	IF NOT @pint550DisputeDispTypeId IN ( 3,4,5) 
		--	BEGIN
		--		SET @intUEGFClaimStatus = 2 
		--	END 
		--END 
		
		EXECUTE dbo.USP_UPD_UEGF_CLAIM_STATUS_EX @pintClaimId ,   @pintStaffId,  @pintOfficeId
		
	END

END 





