/****** Object:  StoredProcedure [dbo].[USP_SEL_OPON_DISP_TYPE_SELECTED]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE dbo.USP_SEL_OPON_DISP_TYPE_SELECTED
	 @pintOponId INT = NULL
	,@intOponDispSelected INT OUTPUT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].USP_SEL_OPON_DISP_TYPE_SELECTED
 * Author:   c-mahsan
 * Date:     8/10/2017
 *
 * Purpose/Description: 
 *     Retrieve Opinion Disposition Type has been entered (through the Reporting Details popup) for all Petitions on a UEGF Dispute
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
			,@intClaimId INT, @intDisputeId INT

	DECLARE @tmpPetitnDisp TABLE(DsptPetitnId INT, OponDispTypeId INT)

	SELECT @intOponDispSelected = 0

	IF @pintOponId IS NOT NULL
		BEGIN
			

			IF EXISTS(
				SELECT tc.CLAIM_ID, td.DSPT_ID
				FROM APP.T_CLAIM tc
				INNER JOIN APP.T_DSPT td ON td.CLAIM_ID = tc.CLAIM_ID
				INNER JOIN APP.T_APPEAL_CASE TAC ON TAC.DSPT_ID = TD.DSPT_ID 
				INNER JOIN APP.T_APPEAL_OPON AO ON AO.APPEAL_CASE_ID = TAC.APPEAL_CASE_ID
				WHERE tc.CLAIM_CAT_TYPE_ID = @intClaimCatTypeId 
				AND AO.OPON_ID = @pintOponId
			)
			BEGIN
				SELECT @intClaimId = TC.CLAIM_ID , @intDisputeId = TD.DSPT_ID
				FROM APP.T_CLAIM TC 
				INNER JOIN APP.T_DSPT TD ON TD.CLAIM_ID = TC.CLAIM_ID
				INNER JOIN APP.T_APPEAL_CASE TAC ON TAC.DSPT_ID = TD.DSPT_ID 
				INNER JOIN APP.T_APPEAL_OPON AO ON AO.APPEAL_CASE_ID = TAC.APPEAL_CASE_ID
				WHERE  AO.OPON_ID = @pintOponId
								
				DECLARE @xml XML

				SELECT TOP 1 @xml = HIST_XML  FROM APP.T_UEGF_RPTNG_HIST
				WHERE CLAIM_ID  = @intClaimId AND RPTNG_HIST_STATUS_ID = 1 AND PROG_AREA_ID = 2 
				ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC 

				IF (@xml IS NOT NULL)
				BEGIN
					
					INSERT INTO @tmpPetitnDisp(DsptPetitnId, OponDispTypeId)
					SELECT	 Col.value('@DisputePetitionId', 'INT') AS DsptPetitnId
							,Col.value('@OponDispnTypeId', 'INT') AS OponDispTypeId
					FROM @xml.nodes('/tdp') AS Data(Col)

								

					IF NOT EXISTS( SELECT * 
								FROM APP.T_DSPT_PETITN TDP
								JOIN @tmpPetitnDisp PD ON tdp.DSPT_PETITN_ID = PD.DsptPetitnId
								WHERE TDP.DSPT_ID = @intDisputeId AND OponDispTypeId IS  NULL 
								)
						SELECT @intOponDispSelected = 1
				END
			END
			
			ELSE
			BEGIN
				SELECT @intOponDispSelected = 1
			END 
		END
	



END