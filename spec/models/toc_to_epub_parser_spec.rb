require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions

describe TocToEpubParser do
  
  describe 'when asked to determine the file type' do
    before(:all) do
      @parser = TocToEpubParser.new
    end
    
    it 'should return "clauses" when passed xml from a Clause toc file' do
      xml = '<TOC><Title>Digital Economy Bill [HL]</Title><Introduction/><CrossHeading>General duties of OFCOM</CrossHeading><Clause number="1">1. General duties of OFCOM</Clause></TOC>'
      doc = Hpricot.XML(xml)
      @parser.toc_file_type(doc).should == "clauses"
    end
    
    it 'should return "schedules" when passed xml from a Schedule toc file' do
      xml = '<TOC><Title>Digital Economy Bill [HL]</Title><Schedule number="1">Schedule 1: Classification of video games etc: supplementary provision</Schedule></TOC>'
      doc = Hpricot.XML(xml)
      @parser.toc_file_type(doc).should == "schedules"
    end
    
    it 'should return "unknown" when the file type cannot be determined' do
      xml = "<TOC><random>tag data</random></TOC>"
      doc = Hpricot.XML(xml)
      @parser.toc_file_type(doc).should == "unknown"
    end
  end
  
  describe 'when asked to generate opf from a clauses file' do
    before(:all) do
      parser = TocToEpubParser.new
      @result = parser.create_opf(fixture('DigitalEconomy/contents.xml'))
    end

    it 'should create xml with correct namespace and metadata' do
      resultdoc = Hpricot.XML(@result)
      package_section = (resultdoc/'package').to_s
      metadata_section = (resultdoc/'package/metadata').to_s
      
      package_section.should =~ /<package version=\"2.0\" unique-identifier=\"UKParliamentBills\" xmlns=\"http:\/\/www.idpf.org\/2007\/opf\">/
      
      metadata_section.should =~ /<metadata xmlns:dc=\"http:\/\/purl.org\/dc\/elements\/1\.1\/\" xmlns:opf=\"http:\/\/www\.idpf\.org\/2007\/opf\">/
      metadata_section.should =~ /<dc\:language>en<\/dc\:language>/
      metadata_section.should =~ /<dc\:title>Digital Economy Bill \[HL\]<\/dc\:title>/
      metadata_section.should =~ /<dc\:creator>UK Parliament<\/dc\:creator>/
      metadata_section.should =~ /<dc\:publisher>UK Parliament<\/dc\:publisher>/
      metadata_section.should =~ /<dc\:rights>This Bill has been published subject to Parliamentary Copyright<\/dc\:rights>/
    end
    
    it 'should create xml with a suitable manifest section' do
      @result.should have_tag('package') do
        with_tag('manifest') do
          with_tag('item[id="clause-css"][media-type="text/css"]', :href => 'css/clauses.css')
          with_tag('item[id="ncx"][media-type="application/x-dtbncx+xml"]', :href => "toc.ncx")
          with_tag('item[id="intro"][media-type="application/xhtml+xml"]', :href= => 'introduction.html')
          with_tag('item[id="clause1"][media-type="application/xhtml+xml"]', :href => 'clause1.html')
          with_tag('item[id="clause2"][media-type="application/xhtml+xml"]', :href => 'clause2.html')
          with_tag('item[id="clause3"][media-type="application/xhtml+xml"]', :href => 'clause3.html')
          with_tag('item[id="clause4"][media-type="application/xhtml+xml"]', :href => 'clause4.html')
          with_tag('item[id="clause49"][media-type="application/xhtml+xml"]', :href => 'clause49.html')
        end
      end
    end
    
    it 'should create xml with a suitable spine section' do
      @result.should have_tag('package') do
        with_tag('spine', :toc => 'ncx') do
          with_tag('itemref[idref="intro"]')
          with_tag('itemref[idref="clause1"]')
          with_tag('itemref[idref="clause2"]')
          with_tag('itemref[idref="clause3"]')
          with_tag('itemref[idref="clause4"]')
          with_tag('itemref[idref="clause49"]')
        end
      end
    end
  end
  
  describe 'when asked to generate ncx from a clauses file' do
    before(:all) do
      parser = TocToEpubParser.new
      @result = parser.create_ncx(fixture('DigitalEconomy/contents.xml'))
    end
    
    it 'should should create xml with correct namespace and metadata' do
      resultdoc = Hpricot.XML(@result)
      ncx_section = (resultdoc/'ncx').to_s
      metadata_section = (resultdoc/'ncx/head').to_s
      
      ncx_section.should =~ /\<ncx xml:lang=\"en\" version=\"2005-1\" xmlns=\"http:\/\/www\.daisy\.org\/z3986\/2005\/ncx\/\" xmlns:calibre=\"http:\/\/calibre\.kovidgoyal\.net\/2009\/metadata\"\>/
      
      metadata_section.should =~ /\<meta name=\"dtb:uid\"/
      metadata_section.should =~ /\<meta name=\"dtb:depth\" content=\"1\" \/>/
      metadata_section.should =~ /\<meta name=\"dtb:totalPageCount\" content=\"0\" \/>/
      metadata_section.should =~ /\<meta name=\"dtb:maxPageNumber\" content=\"0\" \/\>/
    end
    
    it 'should set the docTitle' do
      @result.should have_tag('docTitle') do
        with_tag('text', :text => 'Digital Economy Bill [HL]')
      end
    end
    
    it 'should create a navMap structure with a navPoint for each clause' do
      @result.should have_tag('navMap') do
        with_tag('navPoint[id="navPoint-1"]', :playOrder => '1') do
          with_tag('navLabel') do
            with_tag('text', :text => 'Clause 1. General duties of OFCOM')
          end
          with_tag('content[src="clause1.html"]')
        end
        with_tag('navPoint[id="navPoint-2"]', :playOrder => '2') do
          with_tag('navLabel') do
            with_tag('text', :text => 'Clause 2. OFCOM reports on infrastructure, internet domain names etc')
          end
          with_tag('content[src="clause2.html"]')
        end
        with_tag('navPoint[id="navPoint-3"]', :playOrder => '3') do
          with_tag('navLabel') do
            with_tag('text', :text => 'Clause 3. OFCOM reports on media content')
          end
          with_tag('content[src="clause3.html"]')
        end
        with_tag('navPoint[id="navPoint-4"]', :playOrder => '4') do
          with_tag('navLabel') do
            with_tag('text', :text => 'Clause 4. Obligation to notify subscribers of reported infringements')
          end
          with_tag('content[src="clause4.html"]')
        end
        with_tag('navPoint[id="navPoint-49"]', :playOrder => '49') do
          with_tag('navLabel') do
            with_tag('text', :text => 'Clause 49. Short title')
          end
          with_tag('content[src="clause49.html"]')
        end
      end
    end
  end
  
  describe 'when asked to generate contents html from a clauses file' do
    before(:all) do
      parser = TocToEpubParser.new
      @result = parser.create_contents_html(fixture('DigitalEconomy/contents.xml'))
    end
    
    it 'should set a valid doctype' do
      @result.should =~ /<\!DOCTYPE html PUBLIC \"-\/\/W3C\/\/DTD XHTML 1\.1\/\/EN\" \"http:\/\/www\.w3\.org\/TR\/xhtml11\/DTD\/xhtml11\.dtd\"\>/
    end
    
    it 'should use the correct html namespace' do
      @result.should =~ /\<html xmlns=\"http:\/\/www\.w3\.org\/1999\/xhtml\"\>/
    end
    
    it 'should generate a valid head section with a title' do
      @result.should have_tag('head') do
        with_tag('title', :text => 'Digital Economy Bill [HL]')
        with_tag('link', :rel => 'stylesheet', :type => 'text/css', :href => 'css/clauses.css')
      end
    end
    
    it 'should create a body element containing a div with an id "table-of-contents"' do
      @result.should have_tag('html') do
        with_tag('body') do
          with_tag('div[id="table-of-contents"]')
        end
      end
    end
    
    it 'should create an H1 element for the title' do
      @result.should have_tag('body') do
        with_tag('h1', :text => 'Digital Economy Bill [HL]')
      end
    end
    
    it 'should create an H2 element with the text "Table of Contents"' do
      @result.should have_tag('body') do
        with_tag('h2', :text => 'Table of Contents')
      end
    end
    
    it 'should create an anchor element for the introduction' do
      @result.should have_tag('body') do
        with_tag('a[class="intro"]', :href => 'introduction.html', :text => 'Introduction')
      end
    end
    
    it 'should create an H3 element for every Part element in the xml' do
      parser = TocToEpubParser.new
      xml = '<TOC><Title>Finance Bill</Title><Introduction/><Part number="1">Part 1: Charges, rates, allowances, reliefs etc</Part><CrossHeading>Income tax</CrossHeading><Clause number="1">1. Charge and main rates for 2008-09</Clause><Clause number="2">2. Personal allowances for those aged 65 and over</Clause></TOC>'
      result = parser.create_contents_html(xml)
      result.should have_tag('body') do
        with_tag('h3', :text => 'Part 1: Charges, rates, allowances, reliefs etc')
      end
    end
    
    it 'should create an H4 element for every CrossHeading element in the xml' do
      @result.should have_tag('body') do
        with_tag('h4', :text => 'General duties of OFCOM')
        with_tag('h4', :text => 'Online infringement of copyright')
        with_tag('h4', :text => 'Powers in relation to internet domain registries')
        with_tag('h4', :text => 'Channel Four Television Corporation')
        with_tag('h4', :text => 'Independent television services')
        with_tag('h4', :text => 'Independent radio services')
        with_tag('h4', :text => 'Regulation of television and radio services')
        with_tag('h4', :text => 'Video recordings')
        with_tag('h4', :text => "Copyright and performers' property rights: licensing and penalties")
        with_tag('h4', :text => 'Public lending right')
        with_tag('h4', :text => 'General')
      end
    end
    
    it 'should create an anchor elemnt for every Clause element in the xml' do
      @result.should have_tag('body') do
        with_tag('a[href="clause1.html"]', :text => 'Clause 1. General duties of OFCOM')
        with_tag('a[href="clause2.html"]', :text => 'Clause 2. OFCOM reports on infrastructure, internet domain names etc')
        with_tag('a[href="clause3.html"]', :text => 'Clause 3. OFCOM reports on media content')
        with_tag('a[href="clause4.html"]', :text => 'Clause 4. Obligation to notify subscribers of reported infringements')
        with_tag('a[href="clause49.html"]', :text => 'Clause 49. Short title')
      end
    end
  end
  
end