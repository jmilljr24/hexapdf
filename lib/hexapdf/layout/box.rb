# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2018 Thomas Leitner
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
require 'hexapdf/layout/style'

module HexaPDF
  module Layout

    # The base class for all layout boxes.
    #
    # HexaPDF uses the following box model:
    #
    # * Each box can specify a width and height. Padding and border are inside, the margin outside
    #   of this rectangle.
    #
    # * The #content_width and #content_height accessors can be used to get the width and height of
    #   the content box without padding and the border.
    #
    # * If width or height is set to zero, they are determined automatically during layouting.
    class Box

      # Creates a new Box object, using the provided block as drawing block (see ::new). Any
      # additional keyword arguments are used for creating the box's Style object.
      #
      # If +content_box+ is +true+, the width and height are taken to mean the content width and
      # height and the style's padding and border are removed from them appropriately.
      def self.create(width: 0, height: 0, content_box: false, **style, &block)
        style = Style.new(style)
        if content_box
          width += style.padding.left + style.padding.right +
            style.border.width.left + style.border.width.right
          height += style.padding.top + style.padding.bottom +
            style.border.width.top + style.border.width.bottom
        end
        new(width: width, height: height, style: style, &block)
      end

      # The width of the box, including padding and/or borders.
      attr_reader :width

      # The height of the box, including padding and/or borders.
      attr_reader :height

      # The style to be applied.
      #
      # Only the following properties are used:
      #
      # * Style#background_color
      # * Style#padding
      # * Style#border
      # * Style#overlay_callback
      # * Style#underlay_callback
      attr_reader :style

      # :call-seq:
      #    Box.new(width: 0, height: 0, style: Style.new) {|canv, box| block} -> box
      #
      # Creates a new Box object with the given width and height that uses the provided block when
      # it is asked to draw itself on a canvas (see #draw).
      #
      # Since the final location of the box is not known beforehand, the drawing operations inside
      # the block should draw inside the rectangle (0, 0, content_width, content_height) - note that
      # the width and height of the box may not be known beforehand.
      def initialize(width: 0, height: 0, style: Style.new, &block)
        @width = @initial_width = width
        @height = @initial_height = height
        @style = (style.kind_of?(Style) ? style : Style.new(style))
        @draw_block = block
        @outline = nil
      end

      # The width of the content box, i.e. without padding and/or borders.
      def content_width
        [0, width - (@style.padding.left + @style.padding.right +
                     @style.border.width.left + @style.border.width.right)].max
      end

      # The height of the content box, i.e. without padding and/or borders.
      def content_height
        [0, height - (@style.padding.top + @style.padding.bottom +
                      @style.border.width.top + @style.border.width.bottom)].max
      end

      # Fits the box into the Frame and returns +true+ if fitting was successful.
      #
      # The default implementation uses the whole available space for width and height if they were
      # initially set to 0. Otherwise the specified dimensions are used.
      def fit(available_width, available_height, frame)
        @width = (@initial_width > 0 ? @initial_width : available_width)
        @height = (@initial_height > 0 ? @initial_height : available_height)
        @width <= available_width && @height <= available_height
      end

      # Draws the content of the box onto the canvas at the position (x, y).
      #
      # The coordinate system is translated so that the origin is at the bottom left corner of the
      # **content box** during the drawing operations.
      #
      # The block specified when creating the box is invoked with the canvas and the box as
      # arguments. Subclasses can specify an on-demand drawing method by setting the +@draw_block+
      # instance variable to +nil+ or a valid block. This is useful to avoid unnecessary set-up
      # operations when the block does nothing.
      def draw(canvas, x, y)
        if style.background_color? && style.background_color
          canvas.save_graphics_state do
            canvas.fill_color(style.background_color).rectangle(x, y, width, height).fill
          end
        end

        style.underlays.draw(canvas, x, y, self) if style.underlays?
        style.border.draw(canvas, x, y, width, height) if style.border?

        if @draw_block
          canvas.translate(x + style.padding.left + style.border.width.left,
                           y + style.padding.bottom + style.border.width.bottom) do
            @draw_block.call(canvas, self)
          end
        end

        style.overlays.draw(canvas, x, y, self) if style.overlays?
      end

      # Returns +true+ if no drawing operations are performed.
      def empty?
        !(@draw_block ||
          (style.background_color? && style.background_color) ||
          (style.underlays? && !style.underlays.none?) ||
          (style.border? && !style.border.none?) ||
          (style.overlays? && !style.overlays.none?))
      end

    end

  end
end
