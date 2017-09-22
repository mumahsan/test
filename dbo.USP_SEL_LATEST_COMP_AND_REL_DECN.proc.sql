/****** Object:  StoredProcedure [dbo].[USP_SEL_LATEST_COMP_AND_REL_DECN]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE [dbo].USP_SEL_LATEST_COMP_AND_REL_DECN
	 @pintClaimId INT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].USP_SEL_LATEST_COMP_AND_REL_DECN
 * Author:   c-mahsan
 * Date:     8/23/2017
 *
 * Purpose/Description: 
 *     Retrieve Latest Compromise and Release Decision
 *
 * Parameters:
 *     @pintClaimId		Claim IDENTIFIER 
 *
 * Return:
 *     COMPROMISE AND RELEASE DECISIONS
 *
 * Table and Alias Definitions:
 *		APP.T_UEGF_CST_HIST
 *		APP.T_UEGF_SUM
 *  
 * Called Programs:
 *     NONE
 * 
 *********************************************************************/	
 
 SET NOCOUNT ON;  

	--SELECT * FROM LKP.T_DECN_SUB_TYPE
	--DECN_SUB_TYPE_ID	DECN_SUB_TYPE_DESC
	--		1			Compromise and Release

	SELECT TOP 1	@pintClaimId ClaimId, COMPRMS_DECN_TYPE_ID CompromiseRptnTypeId, COMPRMS_MED_TYPE_ID CompromiseMedicalTypeId, TOTAL_C_AND_R_AMOUNT TotalCRAmount, TOTAL_FURTHER_MED_AMOUNT TotalFutureMedicalAmount,TOTAL_MDCARE_AMOUNT MedicareAsideAmount
					,(CASE CLMT_REPRTED_FLAG WHEN 1 THEN 1 WHEN 0 THEN 2 ELSE NULL END) ClaimantRepresentedFlagId
	FROM APP.T_DSPT D
	WHERE D.CLAIM_ID = @pintClaimId AND 
	D.COMPRMS_DECN_TYPE_ID IS NOT NULL
	ORDER BY D.UPDATE_DATE DESC, D.UPDATE_TIME DESC

END