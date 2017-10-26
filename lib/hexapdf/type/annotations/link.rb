# -*- encoding: utf-8 -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2017 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#++

require 'hexapdf/type/annotation'

module HexaPDF
  module Type
    module Annotations

      # Link annotations represent a link to a destination elsewhere in the PDF document or an
      # action to be performed.
      #
      # See: PDF1.7 s12.5.6.5, HexaPDF::Type::Annotation
      class Link < Annotation

        define_field :Subtype,    type: Symbol, required: true, default: :Link
        define_field :A,          type: Dictionary, version: '1.1'
        define_field :Dest,       type: [Symbol, PDFByteString, Array]
        define_field :H,          type: Symbol, default: :I, version: '1.2'
        define_field :PA,         type: Dictionary, version: '1.3'
        define_field :QuadPoints, type: Array, version: '1.6'
        define_field :BS,         type: Dictionary, version: '1.6'

        private

        HIGHLIGHTING_MODES = [:N, :I, :O, :P].freeze # :nodoc:

        def perform_validation #:nodoc:
          super

          if key?(:H) && !HIGHLIGHTING_MODES.include?(self[:H])
            yield("/H contains invalid value #{self[:H]}")
          end
        end

      end

    end
  end
end
