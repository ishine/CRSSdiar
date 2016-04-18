#ifndef KALDI_IVECTOR_DIAR_ILP_H_
#define KALDI_IVECTOR_DIAR_ILP_H_

#include <vector>
#include "base/kaldi-common.h"
#include "matrix/matrix-lib.h"
#include "util/common-utils.h"
#include "ivector/ivector-extractor.h"
#include "gmm/am-diag-gmm.h"
#include "hmm/posterior.h"
#include "diar-utils.h"

namespace kaldi{
typedef kaldi::int32 int32;

class IlpCluster {
public:

	//IlpCluster(const Matrix<BaseFloat>&, const segType&, const Posterior&, Matrix<BaseFloat>&):

	// extract ivectors for all nonspeech segments
	void ExtractSegmentIvectors(const Matrix<BaseFloat>&, const segType& , const Posterior& , const IvectorExtractor&, DoubleVectorWriter&, const std::string);
	
	// extract ivector for a segment
	void GetSegmentIvector(const Matrix<BaseFloat>&, const Posterior&, const IvectorExtractor&, DoubleVectorWriter&, const std::string, const std::vector<int32>&);

};



}

#endif 