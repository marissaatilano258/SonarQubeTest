/*
// $Id$
// Fennel is a library of data storage and processing components.
// Copyright (C) 2005-2005 The Eigenbase Project
// Copyright (C) 2005-2005 Disruptive Tech
// Copyright (C) 2005-2005 LucidEra, Inc.
// Portions Copyright (C) 1999-2005 John V. Sichi
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version approved by The Eigenbase Project.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "fennel/common/CommonPreamble.h"
#include "fennel/xo/TableWriterFactory.h"
#include "fennel/common/ByteInputStream.h"
#include "fennel/tuple/TupleDescriptor.h"
#include "fennel/segment/SegmentMap.h"

FENNEL_BEGIN_CPPFILE("$Id$");

TableWriterFactory::TableWriterFactory(
    SharedSegmentMap pSegmentMapInit,
    SharedCacheAccessor pCacheAccessorInit,
    StoredTypeDescriptorFactory const &typeFactoryInit,
    SegmentAccessor scratchAccessorInit)
    : pSegmentMap(pSegmentMapInit),
      pCacheAccessor(pCacheAccessorInit),
      typeFactory(typeFactoryInit)
{
    scratchAccessor = scratchAccessorInit;
}

SharedTableWriter TableWriterFactory::newTableWriter(
    TableWriterParams const &params)
{
    // check pool first
    for (uint i = 0; i < pool.size(); ++i) {
        SharedTableWriter pPooledWriter = pool[i];
        if (pPooledWriter->getTableId() != params.tableId) {
            continue;
        }
        if (pPooledWriter->updateProj != params.updateProj) {
            continue;
        }
        // TODO:  assert that other parameters match?
        return pPooledWriter;
    }
    SharedTableWriter pNewWriter(new TableWriter(params));
    pool.push_back(pNewWriter);
    return pNewWriter;
}
    
SharedLogicalTxnParticipant TableWriterFactory::loadParticipant(
    LogicalTxnClassId classId,
    ByteInputStream &logStream)
{
    assert(classId == getParticipantClassId());

    TupleDescriptor clusteredTupleDesc;
    clusteredTupleDesc.readPersistent(logStream,typeFactory);

    uint nIndexes;
    logStream.readValue(nIndexes);

    TableWriterParams params;
    params.indexParams.resize(nIndexes);

    for (uint i = 0; i < nIndexes; ++i) {
        loadIndex(clusteredTupleDesc,params.indexParams[i],logStream);
    }

    params.updateProj.readPersistent(logStream);

    return SharedLogicalTxnParticipant(
        new TableWriter(params));
}

void TableWriterFactory::loadIndex(
    TupleDescriptor const &clusteredTupleDesc,
    TableIndexWriterParams &params,
    ByteInputStream &logStream)
{
    logStream.readValue(params.segmentId);
    logStream.readValue(params.pageOwnerId);
    logStream.readValue(params.rootPageId);
    logStream.readValue(params.distinctness);
    logStream.readValue(params.updateInPlace);
    params.inputProj.readPersistent(logStream);
    params.keyProj.readPersistent(logStream);
    if (params.inputProj.empty()) {
        params.tupleDesc = clusteredTupleDesc;
    } else {
        params.tupleDesc.projectFrom(clusteredTupleDesc,params.inputProj);
    }
    params.pCacheAccessor = pCacheAccessor;
    params.pSegment = pSegmentMap->getSegmentById(params.segmentId);
    params.scratchAccessor = scratchAccessor;
}

LogicalTxnClassId TableWriterFactory::getParticipantClassId()
{
    return LogicalTxnClassId(0xaa6576b8efadbcdcLL);
}

FENNEL_END_CPPFILE("$Id$");

// End TableWriterFactory.cpp