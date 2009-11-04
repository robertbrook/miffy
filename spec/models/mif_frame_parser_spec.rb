require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


describe MifFrameParser do

  it 'should create frame' do
    doc = Hpricot.XML FRAME
    frames = MifFrameParser.new.get_frames doc
    frames.size.should == 1
    frames.keys.first.should == '2'
    frames.values.first.should == %Q|<FrameData id="4312114"><Formula id="1061040">equal[char[x],plus[(*n*)id[cross[(*n*)num[25.0000000000000000,"25"],over[(*n*)times[
char[(*n*)B],char[R],char[D]],times[char[(*n*)C],char[P]]]]],id[cross[(*n*)num[20.0000000000000000,
"20"],over[(*n*)times[char[(*n*)A],char[R],char[D]],times[char[(*n*)C],char[P]]]]]]]</Formula></FrameData>|
  end

  FRAME = "
<AFrames>
  <Frame>
    <ID>2</ID>
    <Unique>4312114</Unique>
    <Pen>15</Pen>
    <Fill>15</Fill>
    <PenWidth>1.0 pt</PenWidth>
    <Separation>0</Separation>
    <ObColor>`Black'</ObColor>
    <DashedPattern>
      <DashedStyle>Solid</DashedStyle>
    </DashedPattern>
    <RunaroundGap>6.0 pt</RunaroundGap>
    <RunaroundType>None</RunaroundType>
    <Angle>360.0</Angle>
    <ShapeRect>16.36399 pc 10.08333 pc 13.772 pc 2.821 pc</ShapeRect>
    <BRect>16.36399 pc 10.08333 pc 13.772 pc 2.821 pc</BRect>
    <FrameType>Below</FrameType>
    <Float>No</Float>
    <NSOffset>0.0 pc</NSOffset>
    <BLOffset>0.0 pc</BLOffset>
    <AnchorAlign>Center</AnchorAlign>
    <Cropped>No</Cropped>
    <Element>
      <Unique>1061040</Unique>
      <ETag>`Formula'</ETag>
      <Attributes></Attributes>
      <Collapsed>No</Collapsed>
      <SpecialCase>No</SpecialCase>
      <AttributeDisplay>None</AttributeDisplay>
    </Element>
    <Math>
      <Unique>4312115</Unique>
      <Separation>0</Separation>
      <ObColor>`Black'</ObColor>
      <RunaroundGap>0.0 pt</RunaroundGap>
      <BRect>0.08333 pc 0.15612 pc 13.6049 pc 2.65476 pc</BRect>
      <MathFullForm>
`equal[char[x],plus[(*n*)id[cross[(*n*)num[25.0000000000000000,&quot;25&quot;],over[(*n*)times[
char[(*n*)B],char[R],char[D]],times[char[(*n*)C],char[P]]]]],id[cross[(*n*)num[20.0000000000000000,
&quot;20&quot;],over[(*n*)times[char[(*n*)A],char[R],char[D]],times[char[(*n*)C],char[P]]]]]]]'</MathFullForm>
      <MathLineBreak>833.33332 pc</MathLineBreak>
      <MathOrigin>6.88578 pc 1.57683 pc</MathOrigin>
      <MathAlignment>Center</MathAlignment>
      <MathSize>MathMedium</MathSize>
    </Math>
  </Frame>
</AFrames>"
end