/****** Object:  StoredProcedure [dbo].[USP_INS_RTNG_DETAIL_SNAPSHOT_OPON_ID]    Script Date: 07/31/2013 15:21:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[USP_INS_RTNG_DETAIL_SNAPSHOT_OPON_ID]
(
	 @OpinionTvp       dbo.UDT_ONE_COL_INT readonly
	,@pintStaffId INT
	,@pintOfficeId INT
)
AS
/*********************************************************************
 * Name:     dbo.[USP_INS_RTNG_DETAIL_SNAPSHOT_OPON_ID]
 * Author:   c-mahsan
 * Date:     5/24/2017
 * 
 * Purpose/Description:
 *    Create Reporting Details Snapshot
 *
 * Return: None
 *	
 *	
 *      
 * Table and Alias Definitions:
 *		APP.T_OPON
 *		APP.T_APPEAL_OPON
 *		APP.T_APPEAL_CASE
 *		APP.T_CLAIM
 *		APP.T_DSPT
 * Called Programs:
 *     None
 *
 *********************************************************************
 * Parameters:
 *		@pintOpinionID
 * Date - Changed By
 * Change Description
 * 05/24/2017	  c-mahsan		Created - Create Reporting Details Snapshot
*********************************************************************/
BEGIN
	DECLARE  @dtCurrent DATETIME = GETDATE(), @intDisputeId INT, @intClaimId INT = NULL, @intCounter INT = 1, @intTotalCount INT, @intClaimStatus INT
			,@intUEGFReportingOriginationId INT = 2 -- 2 = Appeal Published
			,@pintDraftOrComplete INT = 2 -- Completed
			,@intProgramAreaId INT = 2 --wcab
	DECLARE	 @tempOpon TABLE (Id INT IDENTITY(1,1), AppealCaseId INT)
	
	INSERT INTO @tempOpon select PK_ID FROM  @OpinionTvp
	
	SET NOCOUNT ON;

	SELECT @intTotalCount = COUNT([PK_ID]) FROM @OpinionTvp
	
	WHILE(@intCounter <= @intTotalCount)
		BEGIN
			--Retrieve Dispute Id
			SELECT @intDisputeId = tac.DSPT_ID
			FROM APP.T_APPEAL_CASE tac
			INNER JOIN @tempOpon [to] ON [to].AppealCaseId = tac.APPEAL_CASE_ID
			WHERE [to].Id = @intCounter
			
			--Retrieve Claim Id
			SELECT @intClaimId = tc.CLAIM_ID
			FROM APP.T_CLAIM tc
			INNER JOIN LKP.T_CLAIM_CAT_TYPE tcct ON tcct.CLAIM_CAT_TYPE_ID = tc.CLAIM_CAT_TYPE_ID
			INNER JOIN APP.T_DSPT td ON td.CLAIM_ID = tc.CLAIM_ID
			WHERE tc.CLAIM_CAT_TYPE_ID = 7 -- 7 = UEGF
			AND td.DSPT_ID = @intDisputeId
			
			--If the Claim is UEGF
			IF EXISTS (SELECT tc.CLAIM_ID
				FROM APP.T_CLAIM tc
				INNER JOIN LKP.T_CLAIM_CAT_TYPE tcct ON tcct.CLAIM_CAT_TYPE_ID = tc.CLAIM_CAT_TYPE_ID
				INNER JOIN APP.T_DSPT td ON td.CLAIM_ID = tc.CLAIM_ID
				WHERE tc.CLAIM_CAT_TYPE_ID = 7 -- 7 = UEGF
				AND td.DSPT_ID = @intDisputeId)
				BEGIN
					--CREATING SNAPSHOT
					
					--EXECUTE	[dbo].[USP_INS_RPTN_DETAIL_HIST]	 @intDisputeId, @intUEGFReportingOriginationId, @pintStaffId, @pintOfficeId, @pintStaffId
					--EXEC dbo.USP_INS_RPTN_DETAIL_HIST_NEW @intDisputeId, @intUEGFReportingOriginationId, @pintDraftOrComplete, NULL, NULL, @intProgramAreaId, 
															--@pintStaffId, @pintOfficeId, @pintStaffId
				
				
					UPDATE TURH SET RPTNG_HIST_STATUS_ID = 2, 
											UPDTD_BY = @pintStaffId, UPDATE_DATE = @dtCurrent, UPDATE_TIME = @dtCurrent, UPDTD_BY_OFFICE= @pintOfficeId, 
											STAFF_ID = @pintStaffId, UEGF_RPTNG_ORIGINATION_ID = @intUEGFReportingOriginationId
										FROM APP.T_UEGF_RPTNG_HIST TURH
								WHERE TURH.CLAIM_ID  = @intClaimId AND PROG_AREA_ID = 2 AND RPTNG_HIST_STATUS_ID =1 


					--EXECUTE dbo.USP_UPD_UEGF_CLAIM_STATUS_EX @intClaimId, @pintStaffId, @pintOfficeId
						EXECUTE  dbo.USP_INS_RPTN_DETAIL_HIST @intClaimId, @pintStaffId, @pintOfficeId
				END
						
			SET @intCounter = @intCounter + 1
		END
	SET NOCOUNT OFF;
END