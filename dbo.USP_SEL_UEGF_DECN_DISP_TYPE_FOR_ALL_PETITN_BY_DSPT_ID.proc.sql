/****** Object:  StoredProcedure [dbo].[USP_SEL_UEGF_DECN_DISP_TYPE_FOR_ALL_PETITN_BY_DSPT_ID]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE [dbo].USP_SEL_UEGF_DECN_DISP_TYPE_FOR_ALL_PETITN_BY_DSPT_ID
	  @pintDisputeId INT = NULL
	 ,@pintDecnId INT = NULL
	 ,@intIsDispTypeEnteredForAllPetitn INT OUTPUT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].USP_SEL_UEGF_DECN_DISP_TYPE_FOR_ALL_PETITN_BY_DSPT_ID
 * Author:   c-mahsan
 * Date:     06 APR 2017
 *
 * Purpose/Description: 
 *     Retrieve Decision Disposition Type has been entered (through the Reporting Details popup) for all Petitions on a UEGF Dispute
 *
 * Parameters:
 *     @pintDsptId	Dispute IDENTIFIER 
 *
 * Return:
 *     APP.T_CLAIM
 *
 * Table and Alias Definitions:
 *     APP.T_CLAIM
 *  
 * Called Programs:
 *     NONE
 *
 *********************************************************************/	
 
 SET NOCOUNT ON;
	DECLARE  @intClaimCatTypeId INT = 7 -- UEGF Claim
			,@intClaimId INT, @intDecnTypeId INT = NULL
	
	DECLARE @tmpPetitnDisp TABLE(DsptPetitnId INT, DispositionTypeId INT)

	SELECT @intIsDispTypeEnteredForAllPetitn = 0

	IF @pintDisputeId IS NOT NULL
		BEGIN
			
			IF EXISTS(
				(SELECT tc.CLAIM_ID, td.DSPT_ID
				FROM APP.T_CLAIM tc
				INNER JOIN APP.T_DSPT td ON td.CLAIM_ID = tc.CLAIM_ID
				WHERE tc.CLAIM_CAT_TYPE_ID = @intClaimCatTypeId 
				AND (td.DSPT_ID = @pintDisputeId))		
				)
				AND
				EXISTS (SELECT * FROM APP.T_DECN WHERE (DSPT_ID = @pintDisputeId) AND (DECN_TYPE_ID IN (1, 4, 8, 9, 10)) AND (DECN_ID = @pintDecnId))
			BEGIN
				--Get the claim id by dispute id
				SELECT @intClaimId = TC.CLAIM_ID 
				FROM APP.T_CLAIM TC 
				INNER JOIN APP.T_DSPT TD ON TD.CLAIM_ID = TC.CLAIM_ID
				WHERE TD.DSPT_ID = @pintDisputeId

				DECLARE @xml XML

				SELECT TOP 1 @xml = HIST_XML  FROM APP.T_UEGF_RPTNG_HIST
				WHERE CLAIM_ID  = @intClaimId AND RPTNG_HIST_STATUS_ID = 1 AND PROG_AREA_ID = 3 -- 3 = WCOA PROGRAM AREA ID
				ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC 

				IF (@xml IS NOT NULL)
				BEGIN
					INSERT INTO @tmpPetitnDisp(DsptPetitnId, DispositionTypeId)
					SELECT	 Col.value('@DisputePetitionId', 'INT') AS DsptPetitnId
							,Col.value('@DispositionTypeId', 'INT') AS DispositionTypeId
					FROM @xml.nodes('/tdp') AS Data(Col)

					IF NOT EXISTS( SELECT * 
								FROM APP.T_DSPT_PETITN TDP
								JOIN @tmpPetitnDisp PD ON tdp.DSPT_PETITN_ID = PD.DsptPetitnId
								WHERE TDP.DSPT_ID = @pintDisputeId AND DispositionTypeId IS NULL)
						SELECT @intIsDispTypeEnteredForAllPetitn = 1
				END
			END
			ELSE
			BEGIN
				SELECT @intIsDispTypeEnteredForAllPetitn = 1
			END
		END
	

END