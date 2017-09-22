/****** Object:  StoredProcedure [dbo].[USP_UPD_UEGF_CLAIM_STATUS]    Script Date: 4/20/2017 6:52:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON 
GO

ALTER PROCEDURE [dbo].[USP_UPD_UEGF_CLAIM_STATUS]
	 @pintClaimId INT
	,@pintClaimStatus INT
	,@pintStaffId INT
	,@pintOfficeId INT
AS
BEGIN
/*********************************************************************
 * Name:    [dbo].[USP_UPD_UEGF_CLAIM_STATUS]
 * Author:   c-mahsan
 * Date:     7/5/2017
 *
 * Purpose/Description: 
 *     Retrieve UEGF Claim Details
 *
 * Parameters:
 *     @pintClaimId		Claim IDENTIFIER 
 *     @pintStaffId		STAFF IDENTIFIER 
 *     @pintOfficeId	OFFICE Number
 *
 * Return:
 *     NONE
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

	DECLARE @dtCurrent DATETIME = GETDATE(), @UegfCurrentCSTId INT, @UegfSumId INT

	IF NOT EXISTS ( SELECT * FROM APP.T_UEGF_SUM WHERE CLAIM_ID = @pintClaimId) 
	
		INSERT INTO APP.T_UEGF_SUM
		(  CLAIM_ID,
			CRTD_BY, CREATE_DATE, CREATE_TIME, CRTD_BY_OFFICE,
			UPDTD_BY, UPDATE_DATE, UPDATE_TIME, UPDTD_BY_OFFICE
		)
		SELECT  @pintClaimId, 
			@pintStaffId, @dtCurrent, @dtCurrent, @pintOfficeId, 
			@pintStaffId, @dtCurrent, @dtCurrent, @pintOfficeId 

	


	SELECT TOP 1  @UegfCurrentCSTId = ISNULL(UCH.UEGF_CST_ID,0) ,  @UegfSumId = US.UEGF_SUM_ID  
	FROM APP.T_UEGF_SUM US
	left JOIN APP.T_UEGF_CST_HIST UCH ON US.UEGF_SUM_ID = UCH.UEGF_SUM_ID AND UCH.TO_DT IS NULL
	WHERE US.CLAIM_ID = @pintClaimId  

	--SELECT @UegfCurrentCSTId 'CURRENTSTATUS', @pintClaimStatus 'UDPATESTAUT'
	IF @UegfCurrentCSTId <> @pintClaimStatus
	BEGIN 
	 

	UPDATE APP.T_UEGF_SUM SET
		UEGF_CST_ID = @pintClaimStatus,
		UPDTD_BY = @pintStaffId, UPDATE_DATE = @dtCurrent, UPDATE_TIME= @dtCurrent,UPDTD_BY_OFFICE = @pintOfficeId 
		WHERE UEGF_SUM_ID = @UegfSumId

		UPDATE tuch SET tuch.TO_DT = @dtCurrent, 
		tuch.UPDTD_BY = @pintStaffId, tuch.UPDATE_DATE = @dtCurrent, tuch.UPDATE_TIME = @dtCurrent, tuch.UPDTD_BY_OFFICE = @pintOfficeId 
		FROM APP.T_UEGF_CST_HIST tuch		
		WHERE TUCH.UEGF_SUM_ID = @UegfSumId AND tuch.TO_DT IS NULL

		

		INSERT INTO APP.T_UEGF_CST_HIST
		( UEGF_CST_ID, UEGF_SUM_ID, FROM_DT, TO_DT,
			CRTD_BY, CREATE_DATE, CREATE_TIME, CRTD_BY_OFFICE,
			UPDTD_BY, UPDATE_DATE, UPDATE_TIME, UPDTD_BY_OFFICE
		)
		SELECT @pintClaimStatus, @UegfSumId, @dtCurrent, NULL, 
			@pintStaffId, @dtCurrent, @dtCurrent, @pintOfficeId, 
			@pintStaffId, @dtCurrent, @dtCurrent, @pintOfficeId 
		
	

	END 
END