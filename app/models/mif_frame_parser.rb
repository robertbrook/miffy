require 'mifparserutils'

class MifFrameParser

  include MifParserUtils

  def get_frames doc
    frames = (doc/'AFrames/Frame')
    frames.inject({}) do |hash, frame|
      handle_frame(frame, hash)
    end
  end

  def handle_frame frame_xml, frames
    frame_id = ''
    in_frame = false
    e_tag = ''

    frame_xml.traverse_element do |element|
      case element.name
        when 'ID'
          frame_id = element.at('text()').to_s
        when 'Unique'
          unless frame_id == '' or in_frame
            unique_id = element.at('text()').to_s
            frames.merge!({frame_id, %Q|<FrameData id="#{unique_id}">|})
            in_frame = true
          end
        when 'ETag'
          tag = clean(element)
          e_tag = tag
          frames[frame_id] << start_tag(tag, element)
        when 'Math'
          formula = element.at('MathFullForm')
          formula = formula.inner_text.strip.to_s.sub('`','').chomp("'")
          frames[frame_id] << formula
        when 'String'
          text = clean(element)
          frames[frame_id] << text
      end
    end

    if frames[frame_id]
      frames[frame_id] << "</#{e_tag}>" unless e_tag.empty?
      frames[frame_id] << "</FrameData>"
    end
    frames
  end

end