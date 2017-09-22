


alter PROCEDURE [dbo].[USP_UPD_UEGF_CLAIM_STATUS_EX]
	 @pintClaimId INT	 
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
DECLARE @int550DisputeId INT, @int550DisputeDispTypeId INT, @int550OponDispTypeId INT, @intUEGFClaimStatus INT
,@pint550AppealId INT, @int550Withdrawn INT, @intOpenDisputes INT, @intOpenAppeals INT, @int550OpenAppeal INT 
,@intClaimStatus INT, @int550OpenDispute INT , @intPaymentCategoryTypeId INT

	IF EXISTS (SELECT tc.CLAIM_ID FROM APP.T_CLAIM tc
					WHERE tc.CLAIM_CAT_TYPE_ID = 7 -- 7 = UEGF
					AND tc.CLAIM_ID = @pintClaimId)
	BEGIN
	
		SELECT @intClaimStatus = CST_TYPE_ID
		FROM APP.T_CLAIM
		WHERE CLAIM_ID = @pintClaimId 

		SELECT TOP 1 @intPaymentCategoryTypeId = UEGF_PMT_CAT_TYPE_ID
		FROM APP.T_UEGF_PMT_CAT_DETAIL 
		WHERE CLAIM_ID = @pintClaimId 

		--select * from APP.T_UEGF_PMT_CAT_DETAIL
		--select * from lkp.t_uegf_pmt_cat_type
		--SELECT * FROM LKP.T_CST_TYPE
--		SELECT * FROM LKP.T_DISPN_TYPE

		--SELECT TOP 1 @int550DisputeId = TDP.DSPT_ID ,@int550DisputeDispTypeId = ISNULL(TDP.DSPT_DISPN_TYPE_ID,1),
		--		@int550OponDispTypeId = isnull(TDP.OPON_DISPN_TYPE_ID,1)
		--FROM APP.T_DSPT_PETITN TDP
		----INNER JOIN APP.T_DSPT_PETITN_LIBC550 TDPL ON TDP.DSPT_PETITN_ID = TDPL.DSPT_PETITN_ID
		--WHERE TDP.CLAIM_ID = @pintClaimId AND TDP.DSPT_PETITN_TYPE_ID = 26
		--ORDER BY TDP.DSPT_PETITN_ID DESC

		DECLARE @xml XML

		SELECT TOP 1 @xml = HIST_XML  FROM APP.T_UEGF_RPTNG_HIST
		WHERE CLAIM_ID  = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2 
		ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC 


		SELECT TOP 1 @int550DisputeId = TDP.DSPT_ID ,@int550DisputeDispTypeId = ISNULL(Col.value('@DispositionTypeId', 'INT') ,1),
				@int550OponDispTypeId = isnull(Col.value('@OponDispnTypeId', 'INT'),1)
		FROM APP.T_DSPT_PETITN TDP
		JOIN @xml.nodes('/tdp') AS Data(Col) ON tdp.DSPT_PETITN_ID = Col.value('@DisputePetitionId', 'INT') 
		WHERE TDP.CLAIM_ID = @pintClaimId AND TDP.DSPT_PETITN_TYPE_ID = 26
		ORDER BY TDP.DSPT_PETITN_ID DESC


	--	SELECT 		
	--	tdp.DSPT_PETITN_ID AS 'DisputePetitionId' ,
	--	tdpt.DSPT_PETITN_TYPE_ID AS 'DsptPetitnTypeId' 
	--		,tdpt.DSPT_PETITN_TYPE_DESC +'('+CONVERT(varchar(10), tdp.PETITN_FILED_DT, 101)+')' AS 'PetitionType', 
	--	Col.value('@DispositionTypeId', 'INT') AS 'DispositionTypeId',
	--	Col.value('@OponDispnTypeId', 'INT') AS 'OponDispnTypeId'
	--FROM @xml.nodes('/tdp') AS Data(Col)
	--RIGHT JOIN APP.T_DSPT_PETITN tdp ON tdp.DSPT_PETITN_ID = Col.value('@DisputePetitionId', 'INT') 
	--RIGHT JOIN	LKP.T_DSPT_PETITN_TYPE tdpt ON tdpt.DSPT_PETITN_TYPE_ID = tdp.DSPT_PETITN_TYPE_ID
	--WHERE  tdp.CLAIM_ID = @intClaimId

	--SELECT @xmlHist = trdh.HIST_XML, @intClaimId = trdh.CLAIM_ID, @intDraftStatus =RPTNG_HIST_STATUS_ID  FROM APP.T_UEGF_RPTNG_HIST trdh WHERE trdh.UEGF_RPTNG_HIST_ID = @pintHistId

		
		--SELECT @pint550DisputeDispTypeId 'DISPDISP',@pint550OponDispTypeId 'APPEAL DISP'
		IF  @int550DisputeDispTypeId IN ( 3,4,5) 
		BEGIN
			IF @int550OponDispTypeId = 2 --Changed Liability - No Remand
				SET @int550Withdrawn = 0
			ELSE 
				SET @int550Withdrawn = 1			
			END
		ELSE
		BEGIN
			IF @int550OponDispTypeId = 2 --Changed Liability - No Remand
				SET @int550Withdrawn = 1
			ELSE 
				SET @int550Withdrawn = 0
		END  
		
		SELECT @intOpenDisputes= COUNT(1) 
		FROM APP.T_DSPT D 
		INNER JOIN APP.T_DSPT_STATUS_HIST DSH ON D.DSPT_ID = DSH.DSPT_ID AND DSH.STATUS_TO_DT IS NULL AND DSH.DSPT_STATUS_TYPE_ID NOT IN ( 2,7,8) 
		WHERE D.CLAIM_ID = @pintClaimId
		

		SELECT @int550OpenDispute= COUNT(1) 
		FROM APP.T_DSPT D 
		INNER JOIN APP.T_DSPT_PETITN DP ON DP.DSPT_ID = D.DSPT_ID AND DSPT_PETITN_TYPE_ID = 26
		--INNER JOIN APP.T_DSPT_PETITN_LIBC550 D550 ON D550.DSPT_PETITN_ID = DP.DSPT_PETITN_ID
		INNER JOIN APP.T_DSPT_STATUS_HIST DSH ON D.DSPT_ID = DSH.DSPT_ID AND DSH.STATUS_TO_DT IS NULL AND DSH.DSPT_STATUS_TYPE_ID NOT IN ( 2,7,8) 
		WHERE D.CLAIM_ID = @pintClaimId


		SELECT @intOpenAppeals = COUNT(1) 
		FROM APP.T_APPEAL_CASE AC 
		LEFT JOIN ( SELECT AO.APPEAL_CASE_ID FROM  APP.T_APPEAL_OPON AO 
		JOIN APP.T_OPON O ON O.OPON_ID = AO.OPON_ID WHERE O.OPON_STATUS_TYPE_ID IN (2,4,9) ) AO ON AO.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
		WHERE AC.CLAIM_ID = @pintClaimId AND AO.APPEAL_CASE_ID IS NULL 
			
		
		--SELECT * FROM LKP.T_DSPT_PETITN_TYPE
		SELECT @int550OpenAppeal = COUNT(1) 
		FROM APP.T_APPEAL_CASE AC 
		JOIN APP.T_DSPT_PETITN DP ON DP.DSPT_ID = AC.DSPT_ID AND DP.DSPT_PETITN_TYPE_ID = 26 
		--JOIN APP.T_DSPT_PETITN_LIBC550 DPUEGF ON DPUEGF.DSPT_PETITN_ID = DP.DSPT_PETITN_ID 
		LEFT JOIN ( SELECT AO.APPEAL_CASE_ID FROM  APP.T_APPEAL_OPON AO 
		JOIN APP.T_OPON O ON O.OPON_ID = AO.OPON_ID WHERE O.OPON_STATUS_TYPE_ID IN (2,4,9) ) AO ON AO.APPEAL_CASE_ID = AC.APPEAL_CASE_ID
		WHERE AC.CLAIM_ID = @pintClaimId AND AO.APPEAL_CASE_ID IS NULL 


		--SELECT @intOpenDisputes 'AllOpenDispute', @intOpenAppeals 'AllOpenAppeal' , @int550OpenAppeal '550OpenAppeal', @int550OpenDispute '550OpenDisput'
		--2,4,9 
		--SELECT * FROM LKP.T_OPON_STATUS_TYPE   -- OPON_STATUS_TYPE_ID

		--SELECT @pint550Withdrawn 'WITHDRAW'
		IF @intOpenDisputes > 0 -- OPEN DISPUTES
		BEGIN 
				IF @int550Withdrawn = 0
					SET @intUEGFClaimStatus = 2 
				ELSE
				IF @int550OpenDispute > 0 
					SET @intUEGFClaimStatus = 2 
				ELSE
					SET @intUEGFClaimStatus = 3
		END 
		ELSE
		BEGIN 
			--ALLL DSPT ARE CLOSE
			IF @int550Withdrawn = 1
			BEGIN 
				IF @int550OpenAppeal = 0  
					SET @intUEGFClaimStatus = 3
				ELSE
				BEGIN
					IF @int550OpenAppeal > 0 
						SET @intUEGFClaimStatus = 2 
					ELSE
						IF @intOpenAppeals = 0 
							SET @intUEGFClaimStatus = 3
				END 
			END 
			--IF  @pint550Withdrawn = 1 AND @pint550OpenAppeal < 1 
			ELSE
			BEGIN
				IF @intOpenAppeals = 0
				--Claim is close or payment catgory is closed.
					IF @intClaimStatus = 3 OR @intPaymentCategoryTypeId = 4 
							SET @intUEGFClaimStatus = 3
					ELSE
					SET @intUEGFClaimStatus = 1
				
				ELSE
					SET @intUEGFClaimStatus = 2
				
			END 
		END 
		--SELECT  * FROM LKP.T_UEGF_CST
		--select @pintClaimId , @intUEGFClaimStatus,  @pintStaffId,  @pintOfficeId
		EXECUTE dbo.USP_UPD_UEGF_CLAIM_STATUS @pintClaimId , @intUEGFClaimStatus,  @pintStaffId,  @pintOfficeId
		
	END

END 





