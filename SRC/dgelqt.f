*> \brief \b DGELQT
*
*  =========== DOCUMENTATION ===========
*
* Online html documentation available at
*            http://www.netlib.org/lapack/explore-html/
*
*> Download DGELQT + dependencies
*> <a href="http://www.netlib.org/cgi-bin/netlibfiles.tgz?format=tgz&filename=/lapack/lapack_routine/dgelqt.f">
*> [TGZ]</a>
*> <a href="http://www.netlib.org/cgi-bin/netlibfiles.zip?format=zip&filename=/lapack/lapack_routine/dgelqt.f">
*> [ZIP]</a>
*> <a href="http://www.netlib.org/cgi-bin/netlibfiles.txt?format=txt&filename=/lapack/lapack_routine/dgelqt.f">
*> [TXT]</a>
*
*  Definition:
*  ===========
*
*       SUBROUTINE DGELQT( M, N, MB, A, LDA, T, LDT, WORK, INFO )
*
*       .. Scalar Arguments ..
*       INTEGER INFO, LDA, LDT, M, N, MB
*       ..
*       .. Array Arguments ..
*       DOUBLE PRECISION A( LDA, * ), T( LDT, * ), WORK( * )
*       ..
*
*
*> \par Purpose:
*  =============
*>
*> \verbatim
*>
*> DGELQT computes a blocked LQ factorization of a real M-by-N matrix A
*> using the compact WY representation of Q.
*> \endverbatim
*
*  Arguments:
*  ==========
*
*> \param[in] M
*> \verbatim
*>          M is INTEGER
*>          The number of rows of the matrix A.  M >= 0.
*> \endverbatim
*>
*> \param[in] N
*> \verbatim
*>          N is INTEGER
*>          The number of columns of the matrix A.  N >= 0.
*> \endverbatim
*>
*> \param[in] MB
*> \verbatim
*>          MB is INTEGER
*>          The block size to be used in the blocked QR.  MIN(M,N) >= MB >= 1.
*> \endverbatim
*>
*> \param[in,out] A
*> \verbatim
*>          A is DOUBLE PRECISION array, dimension (LDA,N)
*>          On entry, the M-by-N matrix A.
*>          On exit, the elements on and below the diagonal of the array
*>          contain the M-by-MIN(M,N) lower trapezoidal matrix L (L is
*>          lower triangular if M <= N); the elements above the diagonal
*>          are the rows of V.
*> \endverbatim
*>
*> \param[in] LDA
*> \verbatim
*>          LDA is INTEGER
*>          The leading dimension of the array A.  LDA >= max(1,M).
*> \endverbatim
*>
*> \param[out] T
*> \verbatim
*>          T is DOUBLE PRECISION array, dimension (LDT,MIN(M,N))
*>          The upper triangular block reflectors stored in compact form
*>          as a sequence of upper triangular blocks.  See below
*>          for further details.
*> \endverbatim
*>
*> \param[in] LDT
*> \verbatim
*>          LDT is INTEGER
*>          The leading dimension of the array T.  LDT >= MB.
*> \endverbatim
*>
*> \param[out] WORK
*> \verbatim
*>          WORK is DOUBLE PRECISION array, dimension (MB*N)
*> \endverbatim
*>
*> \param[out] INFO
*> \verbatim
*>          INFO is INTEGER
*>          = 0:  successful exit
*>          < 0:  if INFO = -i, the i-th argument had an illegal value
*> \endverbatim
*
*  Authors:
*  ========
*
*> \author Univ. of Tennessee
*> \author Univ. of California Berkeley
*> \author Univ. of Colorado Denver
*> \author NAG Ltd.
*
*> \ingroup gelqt
*
*> \par Further Details:
*  =====================
*>
*> \verbatim
*>
*>  The matrix V stores the elementary reflectors H(i) in the i-th row
*>  above the diagonal. For example, if M=5 and N=3, the matrix V is
*>
*>               V = (  1  v1 v1 v1 v1 )
*>                   (     1  v2 v2 v2 )
*>                   (         1 v3 v3 )
*>
*>
*>  where the vi's represent the vectors which define H(i), which are returned
*>  in the matrix A.  The 1's along the diagonal of V are not stored in A.
*>  Let K=MIN(M,N).  The number of blocks is B = ceiling(K/MB), where each
*>  block is of order MB except for the last block, which is of order
*>  IB = K - (B-1)*MB.  For each of the B blocks, a upper triangular block
*>  reflector factor is computed: T1, T2, ..., TB.  The MB-by-MB (and IB-by-IB
*>  for the last block) T's are stored in the MB-by-K matrix T as
*>
*>               T = (T1 T2 ... TB).
*> \endverbatim
*>
*  =====================================================================
      SUBROUTINE DGELQT( M, N, MB, A, LDA, T, LDT, WORK, INFO )
*
*  -- LAPACK computational routine --
*  -- LAPACK is a software package provided by Univ. of Tennessee,    --
*  -- Univ. of California Berkeley, Univ. of Colorado Denver and NAG Ltd..--
*
*     .. Scalar Arguments ..
      INTEGER INFO, LDA, LDT, M, N, MB
*     ..
*     .. Array Arguments ..
      DOUBLE PRECISION A( LDA, * ), T( LDT, * ), WORK( * )
*     ..
*
* =====================================================================
*
*     ..
*     .. Local Scalars ..
      INTEGER    I, IB, IINFO, K
*     ..
*     .. External Subroutines ..
      EXTERNAL   DGELQT3, DLARFB, XERBLA
*     ..
*     .. Executable Statements ..
*
*     Test the input arguments
*
      INFO = 0
      IF( M.LT.0 ) THEN
         INFO = -1
      ELSE IF( N.LT.0 ) THEN
         INFO = -2
      ELSE IF( MB.LT.1 .OR. ( MB.GT.MIN(M,N) .AND. MIN(M,N).GT.0 ) )THEN
         INFO = -3
      ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
         INFO = -5
      ELSE IF( LDT.LT.MB ) THEN
         INFO = -7
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'DGELQT', -INFO )
         RETURN
      END IF
*
*     Quick return if possible
*
      K = MIN( M, N )
      IF( K.EQ.0 ) RETURN
*
*     Blocked loop of length K
*
      DO I = 1, K,  MB
         IB = MIN( K-I+1, MB )
*
*     Compute the LQ factorization of the current block A(I:M,I:I+IB-1)
*
         CALL DGELQT3( IB, N-I+1, A(I,I), LDA, T(1,I), LDT, IINFO )
         IF( I+IB.LE.M ) THEN
*
*     Update by applying H**T to A(I:M,I+IB:N) from the right
*
         CALL DLARFB( 'R', 'N', 'F', 'R', M-I-IB+1, N-I+1, IB,
     $                   A( I, I ), LDA, T( 1, I ), LDT,
     $                   A( I+IB, I ), LDA, WORK , M-I-IB+1 )
         END IF
      END DO
      RETURN
*
*     End of DGELQT
*
      END
