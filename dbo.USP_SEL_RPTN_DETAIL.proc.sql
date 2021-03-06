/****** Object:  StoredProcedure [dbo].[USP_SEL_RPTN_DETAIL]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE [dbo].[USP_SEL_RPTN_DETAIL]
	
	@pintClaimId INT, 
	@pintPartyRoleID INT, 
	@pintProgramAreaID INT,
	@pintCrtdUpdtdBy INT, 
	@pintCrtdUpdtdByOffice INT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].USP_SEL_RPTN_DETAIL
 * Author:   c-mahsan
 * Date:     06 APR 2017 
 *
 * Purpose/Description: 
 *     Retrieve record relating to the dispute number
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
	
	DECLARE	 @intUEGFRptnDetsId INT, @intWarningOutdatedVersion INT, @intLatestSnapshotID INT
			, @intOpenDisputes INT, @intOpenAppeals INT
			,@dateNoticeFileDate DATE
			,@dateDateOfInjury DATE
			,@dateDatOfDeath DATE
			,@strInjurydescription NVARCHAR(1000)
			,@moneyAvgWeeklyWage MONEY = NULL, @moneyCompRate MONEY = NULL, @moneyTotalCnRAmount MONEY = NULL, @moneyFutureMedical MONEY = NULL, @moneyMedicareSetAsideAmount MONEY = NULL
			,@intShowOponDispn INT = 0			-- if this varible is 0 then hide the Opinion Disposition DropdownList. If it is 1 then display
			,@intHideReportingDetails INT = 0    -- if this variable is 1 then hide the reporting details on screen if it is 0 then show reporting details on the screen
			,@intEditPermission INT = 0   --- if this variable is 1 then user can edit , if it is 0 then they cannot edit.
			,@intPartyRoleTypeId INT, @intCnRDecisionId INT, @intCnRMedicalId INT, @intIsClaimantEmployeeRepresentedId INT
			,@intDraftHistoryId INT, @DecnRendered INT = 0
			--BIZ-BWC-UEGF-Award Details Panel - Med, Indemnity, or Both - Defaulted to Both = 3
			,@intMedicalIndemnityPaymentTypeId INT = 3

			EXEC [USP_SEL_ACCESS_RPTN_DETAIL] @pintClaimId,@pintPartyRoleID, @pintProgramAreaID, @intEditPermission output, @intHideReportingDetails output



			

			SELECT @intPartyRoleTypeId = PARTY_ROLE_TYPE_ID 
			FROM APP.T_PARTY_ROLE 
			WHERE APP.T_PARTY_ROLE.PARTY_ROLE_ID = @pintPartyRoleID

			SELECT  @moneyTotalCnRAmount = td.TOTAL_C_AND_R_AMOUNT, @moneyFutureMedical = td.TOTAL_FURTHER_MED_AMOUNT, @moneyMedicareSetAsideAmount = td.TOTAL_MDCARE_AMOUNT, @intCnRDecisionId = td.COMPRMS_DECN_TYPE_ID, 
			@intCnRMedicalId = td.COMPRMS_MED_TYPE_ID, @intIsClaimantEmployeeRepresentedId = td.CLMT_REPRTED_FLAG
			FROM APP.T_DSPT td
			WHERE td.CLAIM_ID = @pintClaimId
			
			SELECT @DecnRendered = 1 FROM APP.T_DECN DC JOIN APP.T_DSPT DS ON DC.DSPT_ID = DS.DSPT_ID WHERE DS.CLAIM_ID = @pintClaimId AND DECN_TYPE_ID IN (1, 4, 8, 9, 10) AND DECN_STATUS_TYPE_ID = 5
		--IF @intEditPermission = 0  select * from lkp.T_DECN_TYPE
		--SET @intDraftHistoryId = 0 
		--ELSE 
		BEGIN		
			---CHECK IF THE DRAFT SNAPSHOT IS AVAIABLE FOR THIS PROGRAM AREA.
			IF EXISTS ( SELECT * FROM  APP.T_UEGF_RPTNG_HIST URH
						WHERE URH.RPTNG_HIST_STATUS_ID = 1 AND URH.CLAIM_ID = @pintClaimId AND PROG_AREA_ID = @pintProgramAreaID)
			BEGIN 
						--Get the Snapshot Hist Id
						SELECT TOP 1 @intDraftHistoryId= URH.UEGF_RPTNG_HIST_ID FROM 
						 APP.T_UEGF_RPTNG_HIST URH
						WHERE URH.RPTNG_HIST_STATUS_ID = 1 AND URH.CLAIM_ID = @pintClaimId AND PROG_AREA_ID = @pintProgramAreaID
						
						--Get the details
						EXEC [dbo].[USP_SEL_RPTN_DETAIL_HIST] @intDraftHistoryId, 1 -- 1 = Draft Status
			END
			ELSE
			BEGIN
					EXEC dbo.USP_INS_NEW_RPTN_SNAPSHOT  @pintClaimId,  @pintProgramAreaID,	@pintCrtdUpdtdBy ,	@pintCrtdUpdtdByOffice ,@intDraftHistoryId OUTPUT
			END  
		END 

	
		--This is the list of snapshot for reporting details
		SELECT turh.UEGF_RPTNG_DETAIL_ID AS 'UEGFRptnDetsId',
			turh.UEGF_RPTNG_HIST_ID AS 'UEGFRptnHistId',
			turo.UEGF_RPTNG_ORIGINATION_DESC AS 'Origination',
			turh.UPDATE_DATE AS 'UpdatedDate',
			DBO.UDF_PARTY_NAME(turh.UPDTD_BY) AS 'UpdatedBy',
			turh.HIST_XML AS 'HistoryXML'
		FROM APP.T_UEGF_RPTNG_HIST turh
		INNER JOIN LKP.T_UEGF_RPTNG_ORIGINATION turo ON turo.UEGF_RPTNG_ORIGINATION_ID = turh.UEGF_RPTNG_ORIGINATION_ID
		WHERE turh.CLAIM_ID= @pintClaimId AND turh.RPTNG_HIST_STATUS_ID = 2 --completed
		ORDER BY turh.UPDATE_DATE DESC, turh.UPDATE_TIME DESC

		--Get the latest snapshot id 
		SELECT TOP 1 @intLatestSnapshotID = UEGF_RPTNG_HIST_ID  FROM APP.T_UEGF_RPTNG_HIST
				WHERE CLAIM_ID  = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2 
				ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC

		IF EXISTS (SELECT * FROM APP.T_UEGF_RPTNG_HIST WHERE UEGF_RPTNG_HIST_ID = @intDraftHistoryId AND FROM_RPTNG_HIST_ID = @intLatestSnapshotID) 
			OR (@intLatestSnapshotID IS NULL)
			OR (@intDraftHistoryId = @intLatestSnapshotID)
			OR (@intEditPermission = 0)
			SET @intWarningOutdatedVersion = 0 --NO WARNING 
		ELSE	
			SET @intWarningOutdatedVersion = 1 --WARNING, DRAFT IS NOT FROM THE LATEST.


		SELECT 	 @intEditPermission EditPermission, @intHideReportingDetails HideReportingDetails, @intWarningOutdatedVersion WarningOutdatedVersion, @DecnRendered DecnRendered





END