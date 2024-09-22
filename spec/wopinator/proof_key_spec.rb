RSpec.describe Wopinator::ProofKey do
  subject { described_class.new(modulus, exponent) }
  let(:modulus) { "0HOWUPFFgmSYHbLZZzdWO/HUOr8YNfx5NAl7GUytooHZ7B9QxQKTJpj0NIJ4XEskQW8e4dLzRrPbNOOJ+KpWHttXz8HoQXkkZV/gYNxaNHJ8/pRXGMZzfVM5vchhx/2C7ULPTrpBsSpmfWQ6ShaVoQzfThFUd0MsBvIN7HVtqzPx9jbSV04wAqyNjcro7F3iu9w7AEsMejHbFlWoN+J05dP5ixryF7+2U5RVmjMt7/dYUdCoiXvCMt2CaVr0XEG6udHU4iDKVKZjmUBc7cTWRzhqEL7lZ1yQfylp38Nd2xxVJ0sSU7OkC1bBDlePcYGaF3JjJgsmp/H5BNnlW9gSxQ==" }
  let(:modulus_numeric) { 26314565592091861456817347391034761264161164461051435265488661327118239991061110617374426937738301858394632762557644623706284337648130722351137040373729140218981714366018392116560997024473450980237700749557042863848958104688686892202753055547443840589989299188129877915853061580924794911192278120911806242434931064428568856532372255455088434315134313223776766352197696253704424607959424214531609564976209102687453032230450295445600578991842592361995559096890539176926008976984923207549413579102429620779409958442826198470479896158385299857701619730951450169451930175803798457048183388993326216356244491829378205356741 } 
  let(:exponent) { "AQAB" }
  let(:exponent_numeric) { 65537 } 
  let(:access_token) { "yZhdN1qgywcOQWhyEMVpB6NE3pvBksvcLXsrFKXNtBeDTPW%2fu62g2t%2fOCWSlb3jUGaz1zc%2fzOzbNgAredLdhQI1Q7sPPqUv2owO78olmN74DV%2fv52OZIkBG%2b8jqjwmUobcjXVIC1BG9g%2fynMN0itZklL2x27Z2imCF6xELcQUuGdkoXBj%2bI%2bTlKM" }
  let(:timestamp) { 635655897610773532 }
  let(:url) { "https://contoso.com/wopi/files/vHxYyRGM8VfmSGwGYDBMIQPzuE+sSC6kw+zWZw2Nyg?access_token=yZhdN1qgywcOQWhyEMVpB6NE3pvBksvcLXsrFKXNtBeDTPW%2fu62g2t%2fOCWSlb3jUGaz1zc%2fzOzbNgAredLdhQI1Q7sPPqUv2owO78olmN74DV%2fv52OZIkBG%2b8jqjwmUobcjXVIC1BG9g%2fynMN0itZklL2x27Z2imCF6xELcQUuGdkoXBj%2bI%2bTlKM" }
  let(:signature) { "IflL8OWCOCmws5qnDD5kYMraMGI3o+T+hojoDREbjZSkxbbx7XIS1Av85lohPKjyksocpeVwqEYm9nVWfnq05uhDNGp2MsNyhPO9unZ6w25Rjs1hDFM0dmvYx8wlQBNZ/CFPaz3inCMaaP4PtU85YepaDccAjNc1gikdy3kSMeG1XZuaDixHvMKzF/60DMfLMBIu5xP4Nt8i8Gi2oZs4REuxi6yxOv2vQJQ5+8Wu2Olm8qZvT4FEIQT9oZAXebn/CxyvyQv+RVpoU2gb4BreXAdfKthWF67GpJyhr+ibEVDoIIolUvviycyEtjsaEBpOf6Ne/OLRNu98un7WNDzMTQ==" }

  context '.modulus' do
    it 'should return an integer' do
      expect(subject.modulus).to be_an(Integer)
      expect(subject.modulus).to eql(modulus_numeric)
    end
  end

  context '.exponent' do
    it 'should return an integer' do
      expect(subject.exponent).to be_an(Integer)
      expect(subject.exponent).to eql(exponent_numeric)
    end
  end

  context '.verify' do
    context 'supports multiple ruby versions' do
      context 'supports OpenSSL 3' do
        before do
          stub_const("OpenSSL::OPENSSL_VERSION", "OpenSSL 3.0.2 15 Mar 2022")
        end
        
        it 'should verify expected signature' do
          expected_signature = Wopinator::Signature.new(access_token, timestamp, url)
          expect(subject.verify(signature, expected_signature)).to be_truthy
        end
      end
      
      context 'supports OpenSSL < 3' do
        let(:rsa) { double("rsa") }

        before do
          stub_const("OpenSSL::OPENSSL_VERSION", "OpenSSL 1.1.1f  31 Mar 2020")

          allow(rsa).to receive(:n=).with(instance_of(OpenSSL::BN))
          allow(rsa).to receive(:e=).with(instance_of(OpenSSL::BN))
          allow(rsa).to receive(:verify)
            .with(instance_of(OpenSSL::Digest::SHA256), instance_of(String), instance_of(String))
            .and_return(true)

          allow(OpenSSL::PKey::RSA).to receive(:new).and_return(rsa)
        end

        context '>= 2.4.x' do
          before do
            allow(rsa).to receive(:set_key).with(instance_of(OpenSSL::BN), instance_of(OpenSSL::BN), nil)
          end

          it 'should verify expected signature' do
            expected_signature = Wopinator::Signature.new(access_token, timestamp, url)
            expect(subject.verify(signature, expected_signature)).to be_truthy
            expect(rsa).to have_received(:set_key)
          end
        end

        context '< 2.4.x' do
          it 'should verify expected signature' do
            expected_signature = Wopinator::Signature.new(access_token, timestamp, url)
            expect(subject.verify(signature, expected_signature)).to be_truthy
            expect(rsa).to have_received(:n=)
            expect(rsa).to have_received(:e=)
          end
        end
      end
    end
  end
end
