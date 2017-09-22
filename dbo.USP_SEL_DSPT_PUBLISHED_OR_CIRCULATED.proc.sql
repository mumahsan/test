/****** Object:  StoredProcedure [dbo].[USP_SEL_DSPT_PUBLISHED_OR_CIRCULATED]    Script Date: 09/24/2012 14:22:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[USP_SEL_DSPT_PUBLISHED_OR_CIRCULATED] 
	 @pintClaimId INT
	 ,@pintProgramAreaId INT
	,@isPublishedOrCirculated INT OUTPUT -- 1 = Opinion Ciculated, 2 = Opinion Published, otherwise nothing
AS
/*********************************************************************
 * Name:     dbo.USP_SEL_DSPT_PUBLISHED_OR_CIRCULATED
 * Author:   <c-MAHSAN>
 * Date:     <5/25/2017>
 *
 * Purpose/Description:
 *     Check to see if the Decision is already Circulated or Appeal Opinion is already Published
 *
 * Parameters:
 *     		
 *
 * Return:
 *             
 *                
 * Table and Alias Definitions: 
 *		[APP].[T_APPEAL_OPON]
 *      [APP].[T_APPEAL_CASE]
 *      [APP].[T_OPON]
 *
 * Called Programs:
 *     NONE
 * 
 *********************************************************************
 * Date - Changed By
 * Change Description
 * 5/25/2017 [c-mahsan] Created
 *********************************************************************
 *********************************************************************/
BEGIN
	DECLARE  @OpionionStatusType INT
			,@PublishDate DATE

	SET NOCOUNT ON;
	SET @isPublishedOrCirculated = 0

	IF EXISTS(SELECT * -- CHECKING IF APPEAL PUBLISHED
		FROM APP.T_OPON [to]
		INNER JOIN APP.T_APPEAL_OPON tao ON tao.OPON_ID = [to].OPON_ID
		INNER JOIN APP.T_APPEAL_CASE tac ON tac.APPEAL_CASE_ID = tao.APPEAL_CASE_ID
		WHERE tac.claim_id = @pintClaimId AND [to].PUBL_DT IS NOT NULL)
		AND @pintProgramAreaId = 2
		BEGIN
			--T_OPON_STATUS_TYPE -> 2: Circulated, 4: Published
			SET @isPublishedOrCirculated = 2
		END
	IF EXISTS(SELECT * -- DECISION CIRCULATED
		FROM APP.T_DECN DC
		INNER JOIN APP.T_DSPT DS ON DS.DSPT_ID = DC.DSPT_ID
		WHERE DS.claim_id = @pintClaimId AND DC.DECN_STATUS_TYPE_ID = 5)
		AND @pintProgramAreaId = 3
		BEGIN
			--T_OPON_STATUS_TYPE -> 2: Circulated, 4: Published
			SET @isPublishedOrCirculated = 1
		END
	
END

