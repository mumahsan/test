/****** Object:  StoredProcedure [dbo].[USP_INS_RPTN_DETAIL_HIST]    Script Date: 4/19/2017 8:22:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*********************************************************************
 * Name:     dbo.USP_INS_RPTN_DETAIL_HIST
 * Author:   c-mahsan
 * Date:     14 APR 2017
 *
 * Purpose/Description:
 *     Archiving a Reporting detial record.
 *
 * Parameters:
 *	@pintDsptId									DISPUTE ID TO GET THE XML
 *  @pintUEGFReportingOriginationId				ORIGINATION ID FOR EACH ACTION
 *	@pintCrtdUpdtdBy							CREATED BY USER ID 
 *	@pintCrtdUpdtdByOffice						CREATED BY OFFICE ID
 *	@pintStaffId								STAFF ID NUMBER
 *
 * Return:
 *     0 on success, otherwise error number
 *
 * Table and Alias Definitions:
 *     APP.T_UEGF_RPTNG_HIST
 *  
 * Called Programs:
 *     NONE
 *
 *********************************************************************/
 ALTER PROCEDURE [dbo].[USP_INS_RPTN_DETAIL_HIST]
	@pintClaimId AS INT,
	@pintCrtdUpdtdBy AS INT,
	@pintCrtdUpdtdByOffice AS INT
	,@pintProgramAreaId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;


		--IF EXISTS(SELECT tdp.DSPT_ID FROM APP.T_DSPT_PETITN tdp INNER JOIN LKP.T_DSPT_PETITN_STATUS_TYPE tdpst ON tdpst.DSPT_PETITN_STATUS_ID = tdp.DSPT_PETITN_STATUS_ID
		--WHERE tdp.DSPT_PETITN_STATUS_ID=2 AND tdp.DSPT_ID=@pintDsptId)
			DECLARE @dtCurrentDate DATETIME = GETDATE(), @intUEGFReportingDetailId INT, @intClaimId INT, @intUegfPmtCatTypeId INT = 2 -- On Hold
			
			DECLARE @tblPetitnDisp TABLE (Id INT IDENTITY, DisputePetitionId INT, DsptPetitnTypeId INT, DispositionTypeId INT, OponDispnTypeId INT)

			DECLARE	@xml xml, @intRptngHistId INT, @xmlHist XML, @SnapshotNum INT = 0
			DECLARE @intPrevMedicalIndemnityId INT, @intPrevCAndRFlag INT, @curPrevTotalCAndRAmount MONEY, @curPrevCompRate MONEY, @bitPrevHealingPrdFlag BIT, @intPrevHealingPrdWeeks INT, @bitPrevSfcLossFlag INT, @intPrevSfcLossWeeks INT, 
					@curPrevLitnCost MONEY, @intPrevStipulationOrCandR INT, @intPrevCRRptnTypeId INT, @intPrevCompromiseRptnTypeId INT, @intPrevCompromiseMedicalTypeId INT, @curPrevTotalCRAmount MONEY, 
					@curPrevTotalFutureMedicalAmount MONEY, @curPrevMedicareAsideAmount MONEY, @intPrevClaimantRepresentedFlagId INT
			DECLARE @intMedicalIndemnityId INT, @curCompRate MONEY, @intCAndRFlag INT, @curTotalCAndRAmount MONEY, @bitHealingPrdFlag BIT, @intHealingPrdWeeks INT, @bitSfcLossFlag INT, @intSfcLossWeeks INT, 
				@curLitnCost MONEY, @intStipulationOrCandR INT,  @intCRRptnTypeId INT, @intCompromiseRptnTypeId INT, @intCompromiseMedicalTypeId INT, @curTotalCRAmount MONEY, @curTotalFutureMedicalAmount MONEY, 
				@curMedicareAsideAmount MONEY, @intClaimantRepresentedFlagId INT, @intCountPetitnDisp INT, @intCounter INT = 1, @intDisputePetitionId INT, @intDsptPetitnTypeId INT, @intDispositionTypeId INT, @intOponDispnTypeId INT, @intWDD INT = 0
				, @intProgramAreaId INT
			
			--SELECT @intClaimId = td.CLAIM_ID FROM APP.T_DSPT td WHERE td.DSPT_ID = @pintDsptId
			
			--Changing UEGF Claim Status
			EXECUTE dbo.USP_UPD_UEGF_CLAIM_STATUS_EX @pintClaimId, @pintCrtdUpdtdBy, @pintCrtdUpdtdByOffice


			--BIZRUL-171464 - if any of the value changes from the prvious snapshot update the record if exists or insert with 'on hold' status
			
							
				--GET THE LATEST SNAPSHOT DETAILS 
				SELECT TOP 1 @xmlHist = HIST_XML  FROM APP.T_UEGF_RPTNG_HIST WHERE CLAIM_ID  = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2 ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC 

				SELECT @intMedicalIndemnityId = Col.value('@MedicalIndemnityId', 'int'), @curTotalCAndRAmount = Col.value('@TotalCRAmount', 'MONEY'), @curCompRate = Col.value('@CompRate', 'MONEY'), 
				@bitSfcLossFlag = Col.value('@SpecificLossFlag', 'bit'), @intSfcLossWeeks = Col.value('@SpecificLossWeeks', 'int'), 
				@bitHealingPrdFlag = Col.value('@HealingPeriodFlag', 'bit'), @intHealingPrdWeeks = Col.value('@HealingPeriodWeeks', 'int'), 
				@curLitnCost = Col.value('@LitigationCost', 'MONEY'), @intStipulationOrCandR = Col.value('@StipulationOrCandR', 'INT'), 
				@intCRRptnTypeId = Col.value('@CRRptnTypeId', 'int'), @intCompromiseRptnTypeId = Col.value('@CompromiseRptnTypeId', 'int'), @intCompromiseMedicalTypeId = Col.value('@CompromiseMedicalTypeId', 'int'), 
				@curTotalCRAmount = Col.value('@TotalCRAmount', 'MONEY'), @curTotalFutureMedicalAmount = Col.value('@TotalFutureMedicalAmount', 'MONEY'), @curMedicareAsideAmount = Col.value('@MedicareAsideAmount', 'MONEY'), 
				@intClaimantRepresentedFlagId = Col.value('@ClaimantRepresentedFlagId', 'int')
				FROM @xmlHist.nodes('/turd') AS Data(Col)

				INSERT INTO @tblPetitnDisp(DisputePetitionId , DsptPetitnTypeId , DispositionTypeId , OponDispnTypeId )
				SELECT Col.value('@DisputePetitionId', 'INT'),Col.value('@DsptPetitnTypeId', 'INT'), Col.value('@DispositionTypeId', 'INT'), Col.value('@OponDispnTypeId', 'INT') FROM @xmlHist.nodes('/tdp') AS Data(Col)

				--Find if it has any WDD
				SELECT @intCountPetitnDisp = COUNT(*) FROM @tblPetitnDisp

				WHILE(@intCounter < @intCountPetitnDisp)
				BEGIN
					SELECT @intDisputePetitionId = DisputePetitionId, @intDsptPetitnTypeId =DsptPetitnTypeId, @intDispositionTypeId =DispositionTypeId, @intOponDispnTypeId =OponDispnTypeId FROM @tblPetitnDisp WHERE Id = @intCounter
					IF (@intDsptPetitnTypeId = 26) -- 26 = DISPUTE 550
					 IF(@intDispositionTypeId IN (3,4,5))
					 BEGIN
						SET @intWDD = 1
						IF(@intOponDispnTypeId = 2 AND @pintProgramAreaId <> 3) --change in liability
							SET @intWDD = 0
						IF @intWDD = 1
							BREAK;
					END
					SET @intCounter = @intCounter + 1
				END

				--Count of Snapshot
				SELECT  @SnapshotNum = COUNT(turh.UEGF_RPTNG_HIST_ID) FROM APP.T_UEGF_RPTNG_HIST turh WHERE CLAIM_ID  = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2
				
				--GET THE 2nd LATEST SNAPSHOT DETAILS 
				SELECT TOP 1 @xmlHist = HIST_XML  
				FROM (SELECT TOP 2 HIST_XML, UPDATE_DATE, UPDATE_TIME FROM APP.T_UEGF_RPTNG_HIST WHERE CLAIM_ID  = @pintClaimId AND RPTNG_HIST_STATUS_ID = 2 ORDER BY UPDATE_DATE DESC, UPDATE_TIME DESC ) T ORDER BY UPDATE_DATE, UPDATE_TIME 
				--Get the Values from the latest Snapshot
				--DECLARE @PrevRptngDets TABLE(PrevMedicalIndemnityId int, PrevCAndRFlag INT, 
				--PrevTotalCAndRAmount MONEY, PrevCompRate MONEY, PrevSfcLossFlag bit, PrevSfcLossWeeks int, PrevHealingPrdFlag bit, PrevHealingPrdWeeks int, PrevLitnCost MONEY, PrevCnRFlag bit, PrevStipulationFlag bit, PrevCRRptnTypeId int, 
				--PrevCompromiseRptnTypeId int, PrevCompromiseMedicalTypeId int, PrevTotalCRAmount MONEY, PrevTotalFutureMedicalAmount MONEY, PrevMedicareAsideAmount MONEY, PrevClaimantRepresentedFlagId int)
				
				--INSERT INTO @PrevRptngDets 
				SELECT @intPrevMedicalIndemnityId = Col.value('@MedicalIndemnityId', 'int'), @curPrevTotalCAndRAmount = Col.value('@TotalCRAmount', 'MONEY'), @curPrevCompRate = Col.value('@CompRate', 'MONEY'), 
				@bitPrevSfcLossFlag = Col.value('@SpecificLossFlag', 'bit'), @intPrevSfcLossWeeks = Col.value('@SpecificLossWeeks', 'int'), 
				@bitPrevHealingPrdFlag = Col.value('@HealingPeriodFlag', 'bit'), @intPrevHealingPrdWeeks = Col.value('@HealingPeriodWeeks', 'int'), 
				@curPrevLitnCost = Col.value('@LitigationCost', 'MONEY'), @intPrevStipulationOrCandR = Col.value('@StipulationOrCandR', 'bit'), 
				@intPrevCRRptnTypeId = Col.value('@CRRptnTypeId', 'int'), @intPrevCompromiseRptnTypeId = Col.value('@CompromiseRptnTypeId', 'int'), @intPrevCompromiseMedicalTypeId = Col.value('@CompromiseMedicalTypeId', 'int'), 
				@curPrevTotalCRAmount = Col.value('@TotalCRAmount', 'MONEY'), @curPrevTotalFutureMedicalAmount = Col.value('@TotalFutureMedicalAmount', 'MONEY'), @curPrevMedicareAsideAmount = Col.value('@MedicareAsideAmount', 'MONEY'), 
				@intPrevClaimantRepresentedFlagId = Col.value('@ClaimantRepresentedFlagId', 'int')
				FROM @xmlHist.nodes('/turd') AS Data(Col)
				
				--On Hold - System will move a Claim to this status when a Judge's Decision is rendered in WCAIS on a UEGF Claim when UEGF is responsible (information is captured/filled out in Award Details section in the Worker's Compensation Judge Decision, such as Med, Indemnity, or Both, Comp. Rate, Specific Loss, Healing Period, and Stipulation or C&R).
				IF @intWDD = 0
				BEGIN
					IF NOT (ISNULL(@intPrevMedicalIndemnityId, 0) = ISNULL(@intMedicalIndemnityId, 0) AND ISNULL(@intPrevCAndRFlag, 0) = ISNULL(@intCAndRFlag, 0) AND ISNULL(@curPrevTotalCAndRAmount, 0) = ISNULL(@curTotalCAndRAmount, 0) 
						AND ISNULL(@curPrevCompRate, 0) = ISNULL(@curCompRate, 0) AND ISNULL(@bitPrevHealingPrdFlag, 0) = ISNULL(@bitHealingPrdFlag, 0) AND ISNULL(@intPrevHealingPrdWeeks, 0) = ISNULL(@intHealingPrdWeeks, 0) 
						AND ISNULL(@bitPrevSfcLossFlag, 0) = ISNULL(@bitSfcLossFlag, 0) AND ISNULL(@intPrevSfcLossWeeks, 0) = ISNULL(@intSfcLossWeeks, 0) AND ISNULL(@curPrevLitnCost, 0) = ISNULL(@curLitnCost, 0) 
						AND ISNULL(@intPrevStipulationOrCandR, 0) = ISNULL(@intStipulationOrCandR, 0) AND ISNULL(@intPrevCRRptnTypeId, 0) = ISNULL(@intCRRptnTypeId, 0) 
						AND ISNULL(@intPrevCompromiseRptnTypeId, 0) = ISNULL(@intCompromiseMedicalTypeId, 0) AND ISNULL(@intPrevCompromiseMedicalTypeId, 0) = ISNULL(@intCompromiseMedicalTypeId, 0) 
						AND ISNULL(@curPrevTotalCRAmount, 0) = ISNULL(@curTotalCRAmount, 0) AND ISNULL(@curPrevTotalFutureMedicalAmount, 0) = ISNULL(@curTotalFutureMedicalAmount, 0) 
						AND ISNULL(@curPrevMedicareAsideAmount, 0) = ISNULL(@curMedicareAsideAmount, 0) AND ISNULL(@intPrevClaimantRepresentedFlagId, 0) = ISNULL(@intClaimantRepresentedFlagId, 0))
			
					IF EXISTS(SELECT UEGF_PMT_CAT_DETAIL_ID FROM APP.T_UEGF_PMT_CAT_DETAIL TUPCD WHERE TUPCD.CLAIM_ID = @pintClaimId)
						UPDATE TUPCD SET TUPCD.UEGF_PMT_CAT_TYPE_ID = @intUegfPmtCatTypeId FROM APP.T_UEGF_PMT_CAT_DETAIL TUPCD WHERE TUPCD.CLAIM_ID = @pintClaimId 
					ELSE
						BEGIN
							INSERT INTO APP.T_UEGF_PMT_CAT_DETAIL
							(
								CLAIM_ID, UEGF_PMT_CAT_TYPE_ID, SUBMIT_DT, INDEMNITY_AMOUNT,
								MED_AMOUNT, EXP_AMOUNT, INT_AMOUNT, FOR_PMT_FLAG,
								MED_ON_HOLD_FLAG, 
								CRTD_BY, CREATE_DATE, CREATE_TIME, CRTD_BY_OFFICE,
								UPDTD_BY, UPDATE_DATE, UPDATE_TIME, UPDTD_BY_OFFICE, 
								UEGF_AWARD_STATUS_TYPE_ID, AUTHTY_AMOUNT
							)
							VALUES
							(
								@pintClaimId, @intUegfPmtCatTypeId, NULL, NULL, 
								NULL, NULL, NULL, NULL, -- FOR_PMT_FLAG - bit
								NULL, -- MED_ON_HOLD_FLAG - bit
								@pintCrtdUpdtdBy, @dtCurrentDate, @dtCurrentDate, @pintCrtdUpdtdByOffice, 
								@pintCrtdUpdtdBy, @dtCurrentDate, @dtCurrentDate, @pintCrtdUpdtdByOffice,
								NULL, NULL
							)
						END
					IF @SnapshotNum = 1
					BEGIN
						IF EXISTS(SELECT UEGF_PMT_CAT_DETAIL_ID FROM APP.T_UEGF_PMT_CAT_DETAIL TUPCD WHERE TUPCD.CLAIM_ID = @pintClaimId)
							UPDATE TUPCD SET TUPCD.UEGF_PMT_CAT_TYPE_ID = @intUegfPmtCatTypeId FROM APP.T_UEGF_PMT_CAT_DETAIL TUPCD WHERE TUPCD.CLAIM_ID = @pintClaimId 
						ELSE
						BEGIN
								INSERT INTO APP.T_UEGF_PMT_CAT_DETAIL
								(
									CLAIM_ID, UEGF_PMT_CAT_TYPE_ID, SUBMIT_DT, INDEMNITY_AMOUNT,
									MED_AMOUNT, EXP_AMOUNT, INT_AMOUNT, FOR_PMT_FLAG,
									MED_ON_HOLD_FLAG, 
									CRTD_BY, CREATE_DATE, CREATE_TIME, CRTD_BY_OFFICE,
									UPDTD_BY, UPDATE_DATE, UPDATE_TIME, UPDTD_BY_OFFICE, 
									UEGF_AWARD_STATUS_TYPE_ID, AUTHTY_AMOUNT
								)
								VALUES
								(
									@pintClaimId, @intUegfPmtCatTypeId, NULL, NULL, 
									NULL, NULL, NULL, NULL, -- FOR_PMT_FLAG - bit
									NULL, -- MED_ON_HOLD_FLAG - bit
									@pintCrtdUpdtdBy, @dtCurrentDate, @dtCurrentDate, @pintCrtdUpdtdByOffice, 
									@pintCrtdUpdtdBy, @dtCurrentDate, @dtCurrentDate, @pintCrtdUpdtdByOffice,
									NULL, NULL
								)
							END
					END
				END
END