/*
// $Id$
// Package org.eigenbase is a class library of data management components.
// Copyright (C) 2004-2005 The Eigenbase Project
// Copyright (C) 2004-2005 Disruptive Tech
// Copyright (C) 2005-2005 LucidEra, Inc.
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

package org.eigenbase.sql.validate;

import org.eigenbase.util.EnumeratedValues;

/**
 * An enumeration of moniker types. used in {@link Moniker}
 *
 * @author tleung
 * @since May 24, 2005
 * @version $Id$
 **/
public class MonikerType extends EnumeratedValues.BasicValue {
    public static final MonikerType Column = new MonikerType("Column", 0);
    public static final MonikerType Table = new MonikerType("Table", 1);
    public static final MonikerType View = new MonikerType("View", 2);
    public static final MonikerType Schema = new MonikerType("Schema", 3);
    public static final MonikerType Repository = new MonikerType("Repository", 4);
    public MonikerType(String name, int ordinal) {
        super(name, ordinal, name);
    }
}