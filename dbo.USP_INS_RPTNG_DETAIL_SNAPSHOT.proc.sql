/****** Object:  StoredProcedure [dbo].[USP_INS_RPTNG_DETAIL_SNAPSHOT]    Script Date: 5/23/2017 4:20:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_INS_RPTNG_DETAIL_SNAPSHOT]
			@pintAppealCaseId INT
           ,@pintUEGFReportingOriginationId INT
           ,@pintCrtdUpdtdBy INT
           ,@pintCrtdUpdtdByOffice INT
           
           
           
AS
/*********************************************************************
**********************************************************************
 * Name:    [dbo].[USP_INS_RPTNG_DETAIL_SNAPSHOT]
 * Author:   c-MAHSAN
 * Date:     5/23/2017 
 *
 * Purpose/Description:
 *     --	This stored procedure Inserts a new reporting details snapshot
 *
 * Parameters:
 * Return:
 *     --* Return:
 *               
 *                  
 *                
 * Table and Alias Definitions: 
 * Called Prcedures
 * USP_INS_RPTN_DETAIL_HIST
 *********************************************************************
 * Date - Changed By
 * Change Description 
 *
 * 5/23/2017     c-mahsan        Created
 
 *********************************************************************
 *********************************************************************/
BEGIN
	DECLARE	 @dtCurrentDate DATETIME = GETDATE()
			,@intDisputeId INT, @intClaimId INT
	SET NOCOUNT ON;	
	
	SELECT @intDisputeId = tac.DSPT_ID, @intClaimId = tac.CLAIM_ID
	FROM APP.T_APPEAL_CASE tac
	WHERE tac.APPEAL_CASE_ID = @pintAppealCaseId
	

	IF EXISTS (SELECT tc.CLAIM_ID
				FROM APP.T_CLAIM tc
				INNER JOIN LKP.T_CLAIM_CAT_TYPE tcct ON tcct.CLAIM_CAT_TYPE_ID = tc.CLAIM_CAT_TYPE_ID
				INNER JOIN APP.T_DSPT td ON td.CLAIM_ID = tc.CLAIM_ID
				WHERE tc.CLAIM_CAT_TYPE_ID = 7 -- 7 = UEGF
				AND td.DSPT_ID = @intDisputeId)
		BEGIN
				--CREATING SNAPSHOT
				EXECUTE	[dbo].[USP_INS_RPTN_DETAIL_HIST]
						 @intDisputeId , @pintUEGFReportingOriginationId, 
						 @pintCrtdUpdtdBy ,@pintCrtdUpdtdByOffice ,@pintCrtdUpdtdBy
				
				EXECUTE USP_UPD_UEGF_CLAIM_STATUS_EX @intClaimId, @pintCrtdUpdtdBy,@pintCrtdUpdtdByOffice


		END 
    
	SET NOCOUNT OFF;	
END



