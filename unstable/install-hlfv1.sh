ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.17.0
docker tag hyperledger/composer-playground:0.17.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� n@Z �=�r��r�Mr�A��)U*�}��V�Z$Ey�,x�h��DR�%��;�$D�q!E):�O8U���F�!���@^�3 ��Dٔh�]%�����tO�LP���C��lY	�ܭٖgV�ݦ��~@ X[��g4&	ß���H�JBlM���q-*���pO��
��b�G��ۺs3޴�_)���薹�V��s���5�lpB���7�;�e�X7����M���e�z� ��m� ��#���)�P[��:>I�Bhe]X6��$nǲ,�B��3\����6��+6��� ���}�k�*.ۺ��v�>̆Ƚ�Ae<Sn�����
�YT�GH�wN&�W.���%خX3ò�N}�:��+7��(I0��U��$���х��<�C����2v�cy�F��i�Q�m�k��eB-n�/���7»+=��?�V��"�W��e��U0A��������/*��,���	���d�[�4u3	��lJ�n��8~r�_���>����&�kp��g�e�Kl�G�q�G��ވ�Ç�X���B<�q~��'�J�M"�"���(���h��r��mb����,�A��h׺h{�+�|��Ű�����*bX�&1]�;�<�n��l�kPwm��$�@��ZvR/ن�B����r���M��n�وD ��ÚՌLܤr-�p´<�baϭ[6k�P�A	�?C׈鰺U�:	I�s�۱�yo|��*�qY6,��ձn�R��h�:��w����Π�eO7*!lku�M�p�h�P�~Tu���?[#4�x�(��i�BLM'C4)&���h8{���P�B��İ�������rze�����������-�?�a�����.��O�\��I�$(јL�?Q��0l�qO��P�35���[�.j膁�YA6iZm�ٞi�fmp(�p�B�k��>�.9n_�\~ZaS����ӫ��&�E� ���x�{AI��"�V���Q���^���K�	1=àG~�OF���P�4Z9�]���md���Tk7#�BUZ���L���^c�$�� ��1������ ���~�θ_�6�u���>�,ǴѾ��Y}f�����@d&-�t����g|@UD!�36�,���� ]��>�9�C٥��+R�> r��B���_�n:������M~� �!�!�\ԩ�ZY̰A/��_�ͧlr��l��NP6�s�V�?�B]�&������qzL�'j��e��k!4^�3&N/*�S�x�b�8Vs���0� ���n�N�q�$���k�	�?�H���K���הXt����?_7L���X�SS�_�A�A��b2耨D�_c���vRj��[g��ۢ�`�Qk̶���˾���6% J���r�la��	W������~i�PM$(&��]!pV�/���V(K�V]���Q�l��Q�P��域_����A@��<�!�*��פԍj[���.���|�M��L(RO`ey4����u~�%�Pz_���{����A�Ļ������8Ϯ5a�����m�f�M6W��F��=_^�	��Л7hybśB�6A�ޡ�G�l�Y�@y��12�f��<z���Y�H�ei�Li�x�� �
���	4\���ǧ�𣳈��ְ��z�ܾm�-�YV�i���;�����|���?�U3����h�t�R\!-X( �����Dm!,*a����o�Y4���a���m�>�i��q�/&/���/�ܓO5����&�M�@�h��~�z9�3,��sf� �c��u||�wl�E��<`��3g�Y0M����%����u�g�0m�G�EG��h4����c�i�[&8��"bۖ��Z�n���h��͊�"m����u�p�ͳ	��ۛ�xl�5�}�(���D@�X�\v��h_?��;X4��:.i"cܳ�#���1�L�G��[�(TK��#�g`�NȔE��Й�aiؠ1R.��M���O�p?&	ZavB��a��ǐmR�^ձ�D~��iV���ce@>;s���?w�0�z�^�iu���0�~pW�?˥�i�?u���߄����?���?�]��"|�Zs�Z�BD\\�u)fѣ�*����\/��f|�{�- !1,��i��(l���)`���~$G���+�"���]��K!S�?*����$G�ȿ,�-�.0]�Q��>��	�)Dk��~��o��=�aznD���t�X��gu�~PFzُz:��g�B=��p��B�0Z�*O���D�Ypu��?ـ�-�+t�$�r�-���~u�o�����T�2����߽����`�?Q����#!{����X~z�a�X������|�	��s�:n�QB��dI������+�o@�	2B5�]��ӽ|�q��~�	��2�%���5S{�n�pA�y�ށ��:�?���A4=���h����6"fQ�-�݈	���+��.��a�>r5`��̯��pزkb���f� ���Zt�a&���G���+�aa����^��EHd�Q��?ְ:��e��j/)�h:�l���A�r��~_�Mby.�D���`�8n��=RK��;��k^,ݖkQ礪�"��&6��B#�]����U��k��X�A�� �����qY ��rU�b�Qa��'UM.�kqY������W��EeA��z��b�8�e%��ip�t�4��f�yR�f�[���
Nd�2C!��ӟ�dGC�4+[!8�JS�E��
�&K!
y(�QmM�tt���������6J�S,�bj��3�W��2ƙ�d��J�2	���j$�t?g�WF	�л��&��>&��������%(t����c�_��ȋ�Ϲ���7��@f[6�Z�=�c�����|ʞ��ef���/X�|���iAAS��1�����@������|`V���cv�#?ND�׬V��¾Q0��|��D��Q��(�l ��v��*��&( � �X�2�[ex���5M���F\����.����F]��\1��E�cCӈ�]���˥�&��}8�8>��n����00��Y韕�ta�����5�������O�}Bw�����1i��ǹ�G��@���)�O���-���4��)�",�y ��r�w�}����������+���֟&Ѳ�ɲ_�j�&�q\-Wem=_���,�0�E"���r<*kX�+�X��+Ry]Q���[���rㄗԥ��Vm��s������ty[z��2�%-ӱlW��K����Ro��_�,���Q"���w���<�;��,����}�K\�����7���c�W�Y���ǀ�7��a��ѦC8AB����n������Y�U����Ea����8���ջ�1E�K���RL�WA���&,�������G�_���^�����ۖA�EO&Vy\�A��s�x�%&���h���p�S��K����f-��(��@z��%?t	�C�l�3�l&�TKi����e�ɭ�dRՒ5��M��lA�{{�Q�y�Ilu��1�J7��N�v�ݱN�gBp;�Ez(��-U<L'���Q�<}����*%�zy�h���<|�>Ϝ��~�VJA���zkj͌w"'���VI}�cX��V�{z��N_����	紨��%�|;�b'WJK��[s�9��]���ɟe�\)+앲�1M;ciB/��y|�(��N��$utp���::�H�r�q�u�Dn�@�8����5��I)}�K�-?��ߚ�R�˦O�'��~�?+_�����0�N�����cE��0sE� [W�:7v��v��8��L��[ŜWk�d2��Io�BVMly�;�q�q^,厬�v,�Z?�9>Sܵ��q��*�m�6��bF�z�wԝ�u]��Nc��Nj=_�e�\e��v*��[���Y���ͩ2�p[Iu҉H瀎�v-��h_or	���V�T5�th�*��A#��Q���}��X"���5��n�����j�d�ޞ-$3k9]z�l�,�r��o�`Rjj.}��$eg�`���L�>�K'D^�q�8����c��B���a�(�NV"�l���Y���n��X�Ng;�x�+�5_����w�r<֮���[�M�t>5A����p$�y�2k���x 3���Z?�)��ݐ�- �"��������mY�mx���������;D����۾�9���?���((���Ϲ����{���	K}��[۰&���щ-���upP�lgw7�c鑸�(�=�N��#�(�&��c�h��.
;�����J�j�n'���|��;l\dp2���Hn&�y��s�Q�{PP�J� ��Ѷ��ג�c�в�ҞD$���ԡ��Mm��$�\��%s���z�>w�90���f��:��?���e�;��O�fu��Y�$nV'���G�fu��Y=$nV���?�fu��Y�#nV爛�q7�F_Q�������?e���>���?w�������I��"�o.0��&v��a�/��;'ہ]�T�6^J=�R55�c;�I�R�U����E�����~3����2��\#M4�p��;��u�R������۸pM�i��q��;�B|�e�JY�Rk����8g���~;�	�?t�&��wxK��_����)��x��\�	JZ����ⳉ��[a�*�4��0��F��^�v��ބ����N�4x��b�� ��{~�]sxB)R�M�E�ZU�;�ʅ���5zU2�ZE�Ua��O����/��_�^P���<{}���RV����e��]7��[Dc�X$�]Ӣ���İ:,��v�m��R�ce�2�m�q�w�s��'r��w��4��A�p�����5�A'oM�����=}���I/Y�{n�=��&b��?:���x7��B42�^g@]˳z�B��l^��b�[Q�>���M�0e������.Y��ѧ�aͦ �&¶���B�|��N���5`�֥u;��>���RaTy{2&q=-����3T�3�?X�(�*r���{�����>�Ln<�c*�/t��A����~Z`��z�]��Z6���%��ñg����裄7Fz�V�//ý�_]��?����[��)�kmP?�m4�=B�2C��'M�r%���Ud�E'Z������,1�cYu�4����4y��`^�ߚ�;q>�<i��I���u*��(��'N�N�Dj�X �hi���;$f�����A,X �Xýן8���U��ni�O/�\�{�����sc��۳߷,�f��I1��C�rΝ�+�y��MEs�����aU��?/4�*r#.� ��&�������1��o�� ��r�~�6Ic�Sx�]���ZxEĆ�h��s�D�'�4��,���5��P�.꼧>�J% ��[���Юk̀�[����s[�$!�!*�ѷ=�n�_1�|5V��a����w3$�������ə�ρ"��9���	V-@�!oDn�<f�͜�Tsf*�"�`�-g���Y��
�.��T�!l�w�/��ƽ��PQc��z]#���X�i �"7�9��ýi���� �þ�Sad w�#g��|��p�>������ȩm��b7�qC�l�%E��l�HcIU�C�C��7�"�ݭ	�d}���6�~�b�^X���"�Ll��H�ɻ���`������y�~�_Z������'�_h���>����췿��_c? �O	����~�ދo����{?FwE^�^א�IC����t2�T5)!��j&�шT"���j��ii*���T�J)9�Ҩ�J�$՗�9RM�/)���������o���O���ڏ>���[��������~/�}/��D���^]ߢ�c�V�{o��`��7c?|ӿ�o>����ׄV=���c�ߏ��}�g}���߿�h�c�<�F�1x�-˵A6��s�r��Q�I�eX�������Vo4X��Y��c�g���19;�	����gƜ"0�w���.�Ͱ�i��&�M
'݅pҠ���Җ^Z#LÄ��ȯ�w��i�P���y]�9w�v;�Io�[�#s 4�n�F�J�K��)�9.�Qu��չ��e8�迲��S������K���E�a1nQ=鶨���Q�$��2lv8����AyɌ��� ^��\�r\�;���S�mvbڦ�ЅZ��i���26X
�y�8u�Z��N���@���B�ea3��:�(�̽^	t����t��1��vYe��m��g�+z���)��zQr�ӌ��%��f"}*���^�rV*=o�Gֲ����ij���m�M�����I�l�8LW�t����I���J;=��'���*lwuP��y�xd*m*-�;��Ӥ��,=��i��p��~�����C������\JMwF%wF%?}F%���˭M�^��T����J��bg/;��H$�9�dE���^�l��˳b��R��BG-.V�=_D�`0Q(u�-z0({�'z�n	T�A��-z	�t=���h�_�ӳq�Y̔g�CV�zD5��^Gl+'Ks^�\�DUY%mR8*��)�0:|:UhK�^�5�\�hJ��ĵ�>�H_.~�@�<����,����s�����\u�:����*�$�d�JF��nr�8u�?�4O�j6�
��F�R�N�5�i�na���9cI%�r���y�>�d�9kVKCR㊵�C#��kS����>+���~~4ϦG�T^؍�ߋ�ҽco���^_��W��]_�$�7|�^"�7|����bo����p�=�Z��,c�^���ؽ��ގ����yM܇tދ���;���r��a�+�÷akQR��o���X�+��o<�S_}����ޏ����=L��KYYeX�*�e>�d�5�6�:�YV�L�(���32_���/�t+��yr����1�s)H�sa�њ <΅]Gk�r.�c]��}��:��H`��A��P0��tDZdt�<�ø���4�V����B)3K���=vR�
',���:�57"��Q����=c���������#YS�I�u�mg���ѨP�~R>�����t��2Y$�X��G2�t�����w���Q}�i�LKq!�pAe����I�V#���A��Ž��^&�HE�p�Œ�Z֠C���>�6�^-�,��mi�a��(�=	Q;ʤ�G5�A�	J�7�Ѱ�*PBtA�����`�D|���A���z�q�ß�Sq��V|��3��E���ߺ�h�PQ�CE��-�y�=j�J��Vj�>4Wg�����������l+ȅ}(��:�#R�:bE.)��e��[V��jZ ����0�=<�*�cץ���1���]�y@�+�9k�&±�rUN�NT�6:��3�%�^��ݢ-Ϊ�=�1��j%�7���D�
C6�1͊���樗#������q�ȟ�*�nuO�U��w�p�h�S�9OQ�4�x�r��.o�zg�(Ko�S�^(-�ٟ�e:����#��)��eጨn��?�iv�e�Z�w��K���V'\����1&��ݑt��Ң��謘�K��0_2x.C����u�Vn@�	"A��ee˫Ɠg҉��R���P�,ׂD��G������"�Tԁ��h%��ޮ ��"��E!�M�[0B�E���L L��|�0��r,&M����y/(��8�h*�ɞ�6[u�Sfg��\11�py��w���h�:ɭ��	!�t�խ�)Ʃմ�n[��b�\egsˮS(Q�+P�@��(�v�+�&����x�JѴ�nC/���w����bC)%��-�
�T�V�!�T�jȋA���'�GG�E�����IRa���
�1�q�q[�nb&�dW`���J��8�2�b��tr�kָ��)�K�k���ط�� ���{-�����Po�z��Ze�r�P�쾯�65ۙީX�^����b?ws��=���D��{{ٶL+���9Fr�A�Xi�7c����x��)��ӧx��[�k(��9ʋ�{{�\{���:�0%�P=B_���	]�(���7J�=0�:m� 4A��Yf��G�/�~��#�Z�s6ECw�����0;���O��SͶ5;F�`���Oѣt���ܵȗ2*���w�y�q�퉜��L�s��_"�<��'�Lݝ���s3��P���T?�����_�p���5�wx��-�rj##Y�5O� 3<�I�o�"P��O��4��.���xخk��2a�ϻ_~��}����<�����x`��N��w����a=�
{#�F��Ͳ8Ǐ׻=���1�f����gA^RcX�o���D���F��7�q�ch"o�=<��7��-�$h�!��QKPϠ�7��?j=,���Z>z�ЦAx?�P!P��B��5���7��[��"=��&�q�1�3��x�,����X3S���Y�Sаˇg �Wg�x�3'������Z�VY��i��C�G��;H�]�ǟhsa���9�4T�?��>D�A�X�֓��ud�;�Lk�����ܘZc�=,�a��Ƴ�u�H�*ň����z�A�LQ�'kL�VĚ����]�+�a%��@���w���<[�u�
,�N�C��qZ/��D�L ���1V��d��M@8���zRu�+9���\{"�1v��_!�ѕ�º���Lce`Mᵃ-�n���,@�m*r��`Q�_CBH��m#_�:�bLP؂�����}@�N�6YOé�ƾE�V�2������-H���CC���4ςx�"qưyK��-hI	}�ߜ���"_���]*k|;stFa$��q��m�+fM��C�ֿ�5�LdٺV�nF�x�R��C��
?���g�@h��A*�����8���K��]� %=C��p_�!��}8��C�3;���j�Y���%����-���]�����+���'b: �ӕ'�0����p�Ep�{!�8ioB�)P�;S˴���G��(@4��(� ��5pcC�H\��FmfG���F�* `'�t��g#�G�MZ��#�D�6Z�<�V�,0��X�g�a.��r={�(��^��	�����n��5�� 5�粸�D[WG��زռI�⹷��d��MaXN���F ����%:@T@4x@6��[�G����P��#r �d?R33��P<��y��(.{/�#	�D��ebG Uk"��"r��}knl9��IP��&����G��9r�)���|�(h��/z͂��c����t(�)xx�1�v^q�u����t��MM��3�-1�c�#
���q]!���Z��dG�z�	����g��;���:.��Oe��V�*����q+�2x��� � 
���숹��JL}�
�a�Ȃg}Ϻ@3M>���ad�'q�Q�;��8��`�krM��J;��{Q)xxV�+W�|�j=/��p�g�G"IU�'��LJ�Ler�&QI-I��龢h}B��	I"�$��#U�/�si)��j��`\4`P�E.�?���0[(͏������v{<�R��G/T�U{�cB��`�峁$r���$Y��l"�J*Aj)%!�$IJ�S9-�Ȧ�ZR�UBHJ����TF#�������^��}�9q�G��z������3X���W�?~x�c��.,w�v�ߑ���K\�lkM�k�.rU�IW�+�b�;�*OTM���g�["W�Y�ɵZOH�J���m�-�K5�	��$�n�
v�Ϲ�vA��tEh�y�Id{��0��&�0�� �}�{�";V��Lܚ8q݂�jq{��u��d�Kg�j�h;.�u���P�,�õ����0��x�l��#j߽A��/�L9�a���{��� ��j��q�-DG��%���k�:�G,Ǵ��Y�c���k|U|2��x<�Y���4>��}���OTV~0��ݣhހ��M����6��? EK����U|�ʉ�Z�@ �{��q���f���mH��R=�uZ,�����X֓��EP�%�p�蓥E��[ܓ�5S,sA�|��/���'�W0@
,���T.�z��m	�(Ly��3��/��v	���M����u�D��8����
����w#�n�ߚ�k֋���f+���jm������[m�;% 3
�c����]�n�gk�!���p;b��v����
�G�*:��~�����v�8`p�wy�/�L��T�LA�
����u����4��������'P�������������'�L�n�o��J�������w��o�y�wL[��6��6���?������|�?I$��?�������?�<�H��������E�(t���������s���͝�����&�gz���#�ם�w+�m�����*��%��~&��w���*��������d	EK�?{�֜(�v��߽U��t��6'��DDQTP�_�iҙ�i�I:���T*�Ŭw��^�d@�,���<��/�_�Q��ύ&�����������5�?|�s�hM�mo��A��=�ۋ=���W#�8 ��,��'�{��9l�:�g#��6�B��N��!C��'.b�.Cm�9�
�-���^9;kI;X����G�eҕ�$Ƈ��o��M俿���u:<�p�C��>|<�?φ��:�Q��O�����_������O�W����of�~���������]��fY��*P3��&��~>5����k�����������U�� T���?���O3��� �W�f��S��aJ�:T���4�y%�{�g��_�N�����W�p�����0�Q	���m ����_#����� �����M��4~��I�����k�߼��p������K�sZy��!���B���,k��t1}���o�����~޾��]�ݻ���O�}��E�y��UF����>_�>��I��L���:k��ֻ��y�D�h��t^���.��27��#�,	s�=虓Q����e�n'���3r���K���ϗ�O�G�>;^���L��D�ma��7�ۣ�eJ1'S����l�^,w{�o�>��a�&�*g��9r湄.[q�a�hGI�<�g��?F�ڙ&�C3�ib9�H�l9��{p��M݅����g������_���D�P��n�����mh�CJT�h����D��ߕ � �	� ��^��@����@�_G0�_��n����l���i��*�(��C`�?M��0�_^����������3a��Y.,B��$2Nj����v����Ͼ���/����Ko�����a�ٱ-e�g�O��b$%z��ss?ڨBxt���>�cTw�VkT_ը�������;a�`&�X��1]ɞl=�W_
�P<�z�y'@��О-�J��BM����>�[�����Lu)hTLtK�H��O�ޚ!������r��؃h���vT��YB,�3���R�8�OLr�qK-�M6Wy���|:��cf���oh����?�_h��[��,O!�� ��s�&�?��g�)�����I�?_�8,h|`>�9ڧ8�y����9�.H��6 H?�Ȁ	h�'},����G��Q�?��j�+�����j�s,�C����w:��y��y*���>�G~G���or��ڞ����+��vyEs.��K�2[���zz��`�.7[R�+GY�Ĳ�����s�Ft�ɏ��Y��]��+�p�C�g}������֊&�����C#��jC������j�~3>!������ï�G�T죦�N�I�FrtGF����`�r�U@[a�_���'��2��!��qɘ�3z�,�%�(�8���Ka�Ei�R�[�KR��űe[�M�Y0����ij�.��h��O@��&4���?������Є�/������_���_P��Wo�4`h��c�;�GҠ���k��-��/b���#*�H�7S��q%Vγ��������R��������������<}�'� @�ճ� �Jՠ3N���P�"�K ^�@0O��9����yJje�%���=,�a���Z�P���ʲ�QG*��q�զ�2o����|� �޽�7��|�YEnP �k>�w���K���=�^�v���B�~� FJ[��ODX���	]4����9�E���2?�B�� ��q�t@Z�̠-ӥ�y�4��ؒ�[1q�j��Q"N�����@�SR���i�㮍r�c���l�u�8�-d��ERf�ߏ�]��X\�<Z���H$#$�&ջ�$����΢������i����E�&�?�z��(�U������	�梊��Z�{0�q�����G����`��T�����XT��?�������x@�?��C�?��כ����M�D���3���>Fq;��8R���1Ň,�1\Hz��v�GĜ�C�q��BX��04��?��Š�S	~���;���R�9�l�tm�c���,�4�c�d�JM:�2�k�d����ŲJj��[��b�}�;���ݐ�`o��t���l&�1�	����`FǮ�8ߟ$�r��a���6���M8�q���?P��������_%��P��O�����_���]���*B5���71d�7����u�?A���`��"T������B;�!���4��¡�W^�������ql�F�2G��%��q���n�;(k����e�[!�%�3�߷�!?3�}ke#�8�]s2ʽ	-<�T�.���w��ig��;�e��b�i<�&+:g�%2�=����'c69���	Zۛ[qL�˺�B��U3}>1.�\:Q��l[���An�\�9���l����qnqsp�#+�"�F�u�m����70���1ѣ���鱗#AWI5%*�L��h�۳�⼒�'<�ܺ-VV���N�b̟�9��EkL�1z�y�N�����γG�������D��in8#��cٕ�	�����ߚP����ݛ
���[�5��	���ךP-�� x����h�����J ��0���0������$�@#��s�&�?���C����%T��F����$��
@�/��B�/��������������/��u�����O���M����?	�_����c�p,���������5�?�C����������4��!�F �������_`��4��!�jT��?��@C�C%��������O�������GEh���͐��s�F�?}7��_���R����?P��P	 �� ������&��5��������׆f�?�CT�F����?T�������z��������/�#����?��k�?6���p�{%h����h������ ��0����j�Sh����?�_h��[��,O!�� ��s�&�?��g��M���AY�_`ˑ���pP>�A�$N3������X��q��x��h��G}�_4��I�_���Ñ:�:��Ӕً��t��S�'*v�»�L3�0���E-�Q>^���1f����L�䔴�0(G��%�ˑ`H�0:���t��Nw�eۓ�V9�6R���0B��ڹ�#�B���v�]�G�r�u��h������/wm,܄��Lu髵�{Qu��C����5��y]�Zф��_}h���Omh �?��\m`�o�'D��_}���o�:}n��h����[�E(uW�y9�\��6><�a�l�/��׹u��D�A�&��:���l.�K1�;O��3~n�{ԙE�0������ý.$�C�#5�(﷫�R��oE3����ߡ�[p����w|o�h��������/����/��������4B�]����A�}<^�����Ο�O�cR�HfkM�lu���,s���~��{�v7i'���v�~���d����sX�� mɧ5�g(�;����)d.��I�v�y0����Ge�DF��bVBY��~Af�q����Jj4�=#�;i��k�I�坾e�==:�6�o:m����g� FJ[���	+AG^]��E�h��X�}/�C/�M�rbL�5��Ѳ�e�@�SR���w���//�O�>ss5���ٜ�gwa�|��_����h:'�-��R�G�$o�y�H�]wJ���\���f��~�]�����0���o��2A1��� 1�$��[>����[��7�?NB��4���ԃ�O��������#^�E������8�+A������/�_����\O��h�����`���QW��*�Z�ϰ%I�_����ic�Ә=�8/��K���:p�/�����,X/��}�4-:�7���^z�	��{?�N�T�C�{��K��Z�3%���-��K��.F/��ѭty�\�RK�ocK&�`�Q�Ҫ�_���(��:��%MghҮ�1�5T�!�%������)R&,&wrMK��l�;�Kޚ(-�}�`�I������#\�<�8WLma�ܢ�JyO�7o���M�����r�Z���K�y�a��-�����gb.Gf,J"��g��l��~[^���maF��5��*$΁|@��w��̑�dQb�X�c���Ѧ>��|<\[�N��P8m*!�O�V�Fb젞XX�v�6~���97K�UP�J.�����@�}�~/h��������[���Oc>����.��!��2���)&�E`�X,E��d}&�,�y�� ��f�G�	��~����a�������B�͏�0�Cw~�����[���g����KW����˕o�
��rS+0��V|����������P��M�8K��?��U�
�����`T��_��1���J�Z��_�������s�����P�\�M��"���yv����h�S
���w+�!�����C~��w+�!o��Mu�y��^�~/e?�mu?��s�k�%��GFbz-y7�+�!59is~�����n+�`C7֖#H?�]���.%d�bRN7�^����V�C�[�{)�!�~����X�(�E�%�[,�{�t/���"��V���l]
��'���N;>n/��f�cv8e��tp�(F���m�N ����� �a�)/pt)n�%��-���O�U�BUO,�pQ����w�M�[�;��)w<�O� ����}�7���!!@������>��ڤ�ܕ'�nK�$pyo��~����K�P�o(��3��
`�i�H�i�
F��b8 TYf$RJKi�Q�.��I��(��[�t&�:�^a<�����[P��P�=���EvaHP�3Rq��b�Ln�JbC�]���%Ƿ6���c���eK�Z������\���$�}A��J���0�G�g��Y��! ��_
b�
�����Q�?��B��C4���_�!��.���P������o�l���R��h�V�j.]m��j�>��`����P:��>^�1����u�����D� �a��Kղ�m}��ֳ�mݰ��a[�v�ߟ媧�+�CW��+l�t��W���sy`�Z������yؕS���s�A��5�hV�Ԩ�vW��8�2��W���@o�l0���Y�U����b�!VZ�JM�L��l��y�3Z�뵜{!��k�X�1wX�Q��_9�����,^,65��ZM��勛�f��7�.+�X�)F	�e����r�,UW�n��|MZU�a�	
�>(�nob��n]Ƅ�Z��r\�7�v��y-ۥӅbA��E���xU1����d��L��[��.�~��ߌ8�?����h�O(��+r��
���m��G�?E�0�M�b������h�
��O4���D�?��?��e��1� �@����q�4�B��.f�������h�?��o(�������H����?���]"|a<����i��� �ϝ�G�?CB8�6�Y�� �?�������_��
����_0�{G@���?z��ȳ�h���%�����?����������?Ą�Q^���]���h�G(@�P�����"�������?BA���D���m��O��@�?BB�E�D�X��g�h�(�����?��h�鿰��=�����_,���G���?�b������?�(�����?��ю�_����BA����54�?b ��m�X�?}!���
���h�T������G4���G���.b����D�(��l]�r r����߶�����3���b��
K�$ �47a$%CS;��hE�&j*� ���Ь��rF�{�K��|p_�����O���?������v��"�����B��r|M����Щ��wA���\Q(���Z���ݵRDV�v�����4�
�e�,���yk�Q�m>���L�Q��my�KP	a�K�ɱ&m4ٟcuL�4�N�m�,tF�ZM-��X�
c354���kiQݖ*�nfNd��~���T�3�������!*��h�7���G�_t����?�!J�?\���Q���E����{���ը�*�nR��P 0��$����_�4c�������Q���Ur�ycRot�Yq�6��/䰻`��
�����F*�_/W\��R�ˊڛ�%!�̶^a>Y��S�P�%��+�m��E<�
��F�(��"�(Ώب� �b����(����/��������i��ǰ��/��_x2��^�5��_��yN�v5Kj���^�	N���_~����]�B^H[��t�0~�ن��m�/Ԭ����茽�jZ�XI�O�9Lpi��C�$��K�l����dVn�hV�M-k�4�SRKZe�ne�4�\e&g�e����0�?x�y��򓽖��r�Ǥ9���-%�S�G�������Z�{"(�P�9���Z���u홚����i��|y^��$�����c�d���kk5CIL#�L�f�Ȏx��&�Q�ˉX)��&\�wxx_\K���=:���ra�aY���Q�H|���k�����#��)*���?�&{�a<������?��_h���#��]�����������~�?d����Q�?E���c���H�?���8�#������?��'D�����-�"�#������?���P'�GY �GX����	��(�#����?�]�B�������?�d�@��������Cd����#A,��<��D������]�!�������uu�)����U9������(~�u���}�GX��,�w���.�}K�G��=#�wXz����)��Խ�=/ҽN�%��|�[�"[Nd�&��ZX�m҃ue�Y��Ƃ(ɣbB_ͱ^�*,/.d��v��6c�w��`7\�˚^��� �{i��)���+ɹ�B����=���	�󤂵�K�f��;�t��F�_�.����l��aA&���b�'�.r�|�ťF0r��.�=_�*�Ԛ�0l�meU29L0�����4+�I�T3:Ig[���a����#C����"�Q��[��߶�������'���D� �"����_$�(�������_���4���뿻E��n�7	���m��g��!F����ڈ�����G����l6��/�cy9�*ũ�wu����Z�6��P��y�����~A;uO��ʢm(����� ���m@z�.��֡�fE���t)+)I����q�ntj%iT�3�Ku���J��J�٭<r��Z�?MRJ~SL�~c)v�Y�DT���c � �[b � �K1 m���|IT��4���Y��Yo6��k��ɒ�Tb�w3k��&2rK,	��Y��^��Rg��TjΔ��w) �lBV�d���S�w�_�X�?���/(�W(�\��.uK�M ��m�8�����1��?ć���)R�SUVR�LZ�!S*C�,-��R�� �TTB�Ue s,Ȥ9j²��zdā�/���������g�s�6�ru4���/�.Y��Y��q��v����`�e��?���5�����PlG�9�V�wIg��+̙�?���$���I�ݥu*1���eO�r�ɠ��Ü�:<�m����!Z�󹈃�G�?�C��?X*�x㈃�G�_t����?�!r�?.�����M"������=�?{�2�Y^n�BrB`�䜖3�nv�U/_�Z��-���Z��?�#n�e���l��ҕ�ʤ����ʀ�lo����!��sr��&'ۺ�[���]^� +�ɑ�dӰ\{��WnL�B��s�6���hd��@��_���"�P�Wd@�_(����/����_��?HF�8�?�I!����@�i���N��릚��l����y6�����1 �S��, ;-p? 1�ܕd�Xo)I���sv���n��5V��̧y���I(�2�<�Rf�4�mY�3t��E�QNdzꎑ��v�r�L��eC0f�0�=�yX����������Z��#Ah����	����~M|/�]
 �H��'�^�N��ד��\I����Z)��,SXe��ʇ�ۂka��𥙏�eCљ�BzT*����E�Q�@�"=A��%�].��]PD�_ؙSsƖ��5��vU�/i�u���"�t箒�SvMֹJ�*O�Jq��&��&S���_��S��,y��o�<���4$��O�,�!�s���G� ~}4��o��������-����.��|�C��߿k���8owm;�� �oN� 
�2�����ʳW�`X���}�����9���ũd��8%: V�����_�r��X�����O��[����2���_����q�_w�'��H�
��(��?i���?š�p��%e�Lʒ;Ű���F�p��U�q=8����ێnz�d���̉{���ï���P�n�����0�-��geJH'��%Iƽ)���� X�Dw�і�Ų����w�����;�'^��(��N��s������/��'�,;\�]�|	#��_5~�%��?]�Y����l<�7�C1+��7�K�	U���[8�h��_�Y��C���"��-���.�O!�9+��M7 �9������
��������R-��u��aHNp%s����'�����x��O�k `v/�݁K��Ȏ�{�u 
n�7����������r(���/���sC@.~��As'��$�w��<�K|T�l���[��M�<��k����v�C3�k�u�b��/���A�����L��+\=�afAu��Ƿ~�x!����[�i>5�������O�)*EA����D�������$'��h���?��n�?I@?�J�H������o xg���&|_v����`x��wo��=��� 4��`��zdԿ�.X��[V�Y�U����`X!�KF�<���,�kG��/ysg�,h��K���?��яv���.n���.�T�+��I.<������w�<؉l�o�z�kP��Z9��~�i��b �|����g���4y�'�;��f���b���o���"�7W�2�"�'i.�f��rɁ���[�og����7>P���5yC��v�Z�S�)ҋ�R��~ɉGw�E״V�t"_<5�7!
<���|~"{�W���s�����I���� ��O1��0�4�������n*X�2��-y�e����`�C�����P�����t���ߝC����s҄��Ai&�C�>��������GX�/�?H���ZN~�y����`,q��^���l?��iZ�r]%�|K����{��^���;|g?�w��/��.xx�����}CZ��/�����DU�n9T��$��Jk� ݄�MEPdЪ,�&m��;�v8���n���i��U]	��0�����k��?񤷰/�����\��>
^����=�\�v��A�u��4�����,�c\��Xͱ�ߓɽC5�\o߻x�����E�gO
��<��9��ow�R��~��Oǲ��2���_��\AA�kW�>S�ӽݞ_�K'��n�tc���}�v)��o�ڥl��o��i޶�� �ʃ{R�}��3ðc�̇Jn�����������9�}���.IҒ$�ce�P�t�H���޵�8������ژٙ&{^[�KR�3���U�3�(i��t9�v���ҙi;�t�+3�\5jiw-���7$V�+,�+b.����#DD>�v���k�jF���.;����|��m�nE��!�	G%! ��(PшkQA�	4�D>2� �_�����<�Z��B�A�I�P��;���dG�r���e%Y�Ѯ���H4������RH�4�V<�6�}PE����D@i�?�A:���|0��Y�k�2��畂���Y�F�3�-����xŔ�� [��9U��8=&���|a����j�����������Z�/����lc�r�t�T.��=q�̞��΅��|���s��\�Z�7�/�
Γ�f��_(�⿘ us�s-�e��6���Ƃ�
-h�um�
gw��n��������������(,��������Z���5A8��q^�/	��L8x��w-����#�k�7�l����/m������C9�
�4�E�"%RtLh�ڴ����V,H#�LS2�c�X�:��bT+e��(��w|�6X%L������p���#��# �^A{�K�� ��p�����ě���~��Ϳ�E|��2���6n-�lm�;xh��o�L ��]�d�����W�$�!�
3}�K��Ȃ���Ip�<r�^���{����*&��:Α�p�>%�p.���u<�Ʉ>�x]��y���,��*(�$+2��.��VY���N^e͔w8q�Vdc�d��ؕw���{��yq��U���[���ۊ�X�&����#��*t�^��iLj��^^$K>~�I�X∞S���!pM�贈���\&L����F��CYģX�e�O�z.�U}�õ�����pذ��zE�`V��}�2����;Ǚ;/~"����,ơ�W1�]N�j�v�+��ji��_���2�u-��^K���7:n�5��F�[��;p�.-M!tTd��F����г�����j�$y�����0NT��O/k2�>����hSp��f� @A#�f�B���E6!��������0�5�Ih*Tɑ��+G�*��H1d�!Y�b�G_p�P�Ǥ)h&n��}�G�W]��ƃ"V����]�r��7�ԡ�c(��T�Gp�Aeؾ�u�0R����(˄��z��g����u���.�f��'O��$2�*����ք�þ�6�m����f�4
�z%(BN��IC6�h��eu�{eSۧmWG���0M؃���-�r������ü���,ݺ����U����$2]NH��-�`��,����S.�^�~���>Y�E/+
��@7dG��Ms~�w%�e'#;�X�9��<�=-%�����J_�O�ߓ��R�x�H�v(w��#h�f�D\ڗ����p�����nt�
�JE��)����?t�9��DdڱH5Y�H�#��<p����t(ٞn�a��2D�?#k�:*Q�P���pہ;X&[��u�9*ݴa�B�c�D�n�˭E�����	�ET/�'q�a�E]U�a^�̩-�8��}'\K7��}��"�[ɀ�0}�~��0=ys8���ĩ����ɒ����l+)�"��$?��X�$,a������#�ܕ:g����nj�U����V��a�t����lm��̧��i�������W�����U����O~����ן��;��ߥ���ƭ��6�l�������Ez�!EC�,:$E���!:ҒBTL3�@��c-Ƃ��D%*d�B4�B�l�Ļ��'��~�F?��>����	��=$~; � ~+@������.�I����w�^��F��[��r6�����/���o��O��t|�	�"����3`pʽD��.N9�k��h}�Rs��̘��$�\����|ٜ����IMr��y��Ê,N"���iSh4���R>^�!s�|�L��Ts�LO8*�Z�T���v�._n�r_eV�E>��X�5�#�g�8೼�N���� �;qm8��$=q��q�~qz

��RS�>���B�~9H����h�ons��,>��'ݽ���j2֤vr<4��U�r��P5U�b��\�Q�n�[�;O��*u2˙J=32]���Ӂ5���x6�apr�x�8�i�u�kv���E89svh���)�S�dK=���N6h�F5�D8�f��tu:<.sG�,�����	����&fFoO���������Ƣ*3�V������	S�������2G�Xg�¸Q�[6�E����V�8��r-�m>zhV�΀����s�)��I�JFE���=��♙~Q�T_-���/T*Sc�\P�T&6k�m�M��4�d;_K]���8�v�_'��k\�X����i74z���U��>����[�'�����`��ro�� �� ��3���4^�2�i����q�p�4z�NvA�R�ųZ��8���z�X8`҂TU��4#��$-T#��K�J�I�f���W���<Kg � ����f;I�wC��cY�J�|ܤ��,Ma�s�0*���`p2Te��E#�H�y%�c�� �xV����J�O�\9A��0H�:'�ڱLG�y�i���Zs;����5���8!�u�N�9�Bn&�i=5R܄�EFUpt�gKB@�%�Xd,��,������j�w��L8��
J�}]���Nj|T�*�xoN��f@�$��i��\��bN�����|�0[��Ҧ�����'��΀��t��� ��u��Rx�*�Hn�ƃ��&UYJ�٨���L�9=���RK
�A�(�*' �4�0��t�2Q�X�Ƞ��p�m�>�� ��<���4u���`ct@ �z�0���Jg�ۛO(1"q�I�[>9��왟<�ӱ"F�t,,S��0���''i��щ)3&d��Op�Q>�j!�ʩL��P	כ��!��h'�v��N��� u��y�{���{��o�"�!6�;��퍗6_E�����,Nx/^�=7�X	��C�@��V�Ⱔ��8#> ^�x��py�|g�ɷ���9�����/x�&���+�m�%��g#���-N"���o�!��77��q�x���=�w�y���?;W���H\X�|Ί��5S���Y!����x�����'鲃�8a0�$�\�r �}Os��"�4� ��������
��x9�X�l9>����(�經Ò��A,\��)6�
�A�kg��A��T�b�MZ�h3kڤY3�n̏�\GᆹC�. �⇃5 �B+5(qv����vf;q��XBF?�h:K��z��r��9{ ���ʑ<뗎2-�֭�T�&E��Qz� ��+��~}"�t�VQ�r�M�u�ܥUy�9������D�W�{ƌ�t�g�[�q��$������qn���2?��S�|�쌺��)�?|�����9���W���=t���u�#�*N%k��<�z�Y!ٟT�qvZ�K��RyW��e��w�}�{���t��PG���L8�/!�м'Y��H��qGPK�R�8c�F��f��iU�����7�r}(7��~��J^���ʠ����̕X-�$z��f�W�O
>e�1�2��T�Iu�jc0��S.�\'���;j{�itO���; ��p��D&w
�7Y�+e�����@<���L�P�e�Z]�r��8�67'M>��V*5(0�d��f��v?�U�T�m��lb���.���@��(3z47/��s��y�Lܼ���7o�8��-���7����K_'^�n^���7^�Lh�2_����"����ٴ�>#6܌����vse����P&�w�+���^�-�`�ݪ2����W7�ݧO�R�>}Jzy�^�yj�mW�u�p;���|��(����Hv�g��`4�Q�^?��f��hV��Pw�\{�L��;�k�I��U|�92p�m�/|��s�38�$�i�&����g�5>s-���x��w�|��2�6�B�s��_ 
������qs�w�����"kt�?�~�tn:�vȤ�n��B�R��B�� ��L�O"�03:��I�&aR�IC��.������-]WQ�/�]N��} ���5x��>���.��o퓏�_�vT���a	�`�,����b����w̺\��a�i������r����abM�^6��5]�������I]�C������x�	j9�����G*�`ѴP�1�b�058��4�8ӊ��n��UL��nv�����&h$��Ƽ�1^8�s�$9�4��H�HM�65
v9�,������ru ��r��VñU:���E��Sc�|�H�'���gq� ���������G���_����;�U}���em���>{e���s>j\�.Ԉ��^��	�Y�%=0����T7��&�s(X]�i��zӫdi�x�lR��s�4j`�AE'�����8�]lrO	 ߰d(��u���"���
Xj��B'�/�H|� ��� �\�����;Τ�]�@�V4�}�OK�� ���T���N?� �2���/��i�$;��2���G�����@�Nl*��FC�kND낖�28�Ļ�8��M�OC#ᐧ�5;�x� �+���HJuu'��q���й�Ɖ3�0����ς#�$�5S���&��aX�:W�Yő���j���)y��3���p�I��`�q��HtI��޾����LW� ��ف�[h_b��n��v_��N�*�P�noɽ���g�'�e�b��6�ͯ0@Q�X��d�'~�DKn�n�62��Be1�^�>4�����gi����J�� ���15,x
�o.��cKE���]�3;��`4XW$;��l
���q���0u��A�ml���vTm|f�N���M?]o�B�Ď���@��eCT�,i�₱݅�s��5;Ǣ$�sW���ز������G�n2�%Ă��V�n�>��~�F�'*�%"Kl����5v�!$�9@r��9n�}d �$6�![�x�c`����3}�
�Zj�C�\i��i��웸u��i*���~,.4��r���,�������Ҕ��� ��B��[�~�Mt���4ٚ�F��˞�W�+f�gǮ�>�y=���B$�_�"�������~]�?Ͽ�w��:ι�� �'��������ߵ<f�>�A� �PD�+Y�j�J���@訐o᳸o��D��([�S�߹�u�暂�T��ػ��D��{ϯx��.�������^&� ��|�b�	�׿�I�I�I:@w��H���9,��g�uڊ�|g
��H�З�:y������������;c��D&V�����/�/����8{^�+_���qWʧ��zy�Ipx�K��2��.Fq�;>N��9��8C��q���c�:$A�Pl�;��F�d*'	��=]���ǿ���N"f�t����A�s��l��Ϋ���4��P���ԿO9�������s�fɊu���b*�P���Ԫ�V����݆���M�d�Rl�;v�سG'�ښm(�JM�~��rhY���P�;�=�n������a�5��O9�׎N�S�Q����dC��C����I�],7h�H�Mh���p�n����7�kC���Q�`*e�_���t��\�{��u5�2�p��O����ӳ������S�٭/�����N�]�L���ޓ	��T4S��G^�Y[��C�ƭb���f6�o���(�&M���Y����Nw|�~�����f择�����랹�����&�$�����ݼ�xk*�N�ҍ��}���n�h}���n�K����W� L>����aY=���L̚�_e�)���|���>d��ZK����9�����oB��[o��&?���O�sw����ν}����?���l�����c��xN}����'�9q��O�tx2��|߳�G:��u~u?Xs?�}X5K�C���ݔHH�~v�?��{�v^ڏ&e�y�0ShIo[V��VO���?BgA�O�M>=�����o����������,������x����0�Y�����s��O�4��f�o�7����<���/�x| ?���c��_��Gs�q;���>�#܏�z�ؼt�k��C�����F������,���O'���>����?������@f����2H���"+�a��$��+��0X���@4�@�[h�߄B�Kl�8���	2���;�0p`6`9?��c�; i/��g9���G�,�����x��gM�/�"��$�_�?���?鿻���ѕ޽�S+B�/�E�*;�6l4�xP���|1m���
)���Z1�\�m������o�gh	�9��Q]1Kq�;P*�=o�Q�L��i�z�k��xo�X��t���7���}��ö�N+R���`�uFsi�D��������C���������%��"��W��3A���R���Ȍ�������:���������������=�k����;�?�P���������D���?w���k���g�����H�P%������?)������ l�	[u�V�t	�P������#A�y�y�����
���U��F(�Ch�(B�O����$	�x-�o$�0���)߸�!ǵJ��_	�h܊����c.���!.��?�I�'����g�Q1�����~"����c��3��(���}޷}"��3=Q�&������8�!ZE#�Oo�檷�t��1�ZK^N�i�ʵ�FǪ�&.2<�����W�.P�s:�:��}޷}"o��T��t�FJX!6ʶ)�������pA1���]���d0\��g�>��z�N[��s��� {����Ҩ�b֥pII��ɽ�^݆��v�^�f�]�nm,A�s�n�2��~3Y��2h*Hc`p��F���A!����"�s�(� r��_[���a�?7���%*c"�O�")��� �?���?��S���)��������Q��9�����
��4s���(������?���W������}���{���{a��ޘ��Lk��������^����wa}����|X����_�WZK���\b��Ӡ3�����Mce�4!��5�*y�h�%�X�SUM�������W�3�j=q�.1�V�c����z�q\���z�� �뗐~,J�X[����u�_]ƷO/h5���S#�r$���n|3a�y /�yo81z�Z4I�DUS1[	��d��G)Qls���|����,�5^:�i~�6�3�����	
����G���E���m� �������E��H����LP(��.�z�=��}��]��1��� (�sY��<�dH�a=�t=���&y���x3���i���g�����}}���:ZFM��[��r&�%rW�e��
]U���op�o�w�5ܹ�pۦ�����r�KK�������7v�|1��Iɍ֬F�2��V�����w�hH��f;����W���WQ��?�懼���)���"<�!�������E���;��y_���"�?���w�[��4��R��;!�ȶoa�3�Iu�x�q�?�h;����O��LMiKa��y��~iިyD�� �G�$��6	1+�Hs��[m�t��be�-5��,f�ȫw����t�4���b<�I���"<�=盷�/��"�A�W~��/����/����远�?�s@!��)�{��(�_xM���'�2����ڨ���Y���e\)�ޕ��?����(�����!'�5�� ���� �YϦ�p���ڞzc!U�"�& �� 4v�e�t-U7R?.������^*��~k��|l۲�JG�(��ծ�zWP�K�7�+��}��Oꭱ��f>�}/F�~#E�u»SH|���+%{ 4Ze16�S<�C�,��'"�aÀ�4끩�ڢ�r�q��	��	5�3�5ҮE&��#C
/���KRy.N�]-NjBB����<�P���uL_o�e��7GO,�zzE�zY�Α3X���2ת�H<؋Z� ��0��F��lVF��ýh�h�0i�諁P�F�"�?�J����	2x�{TxY��k�XJ�NA�G(�X����g�l�<���������8�d�������|�����	��?�w\�v\��(c}�ǉ��0�w�a(>`1���q�d9�!	����b�a� ;?E����	�_���������e��͆�&��#�h�i/�154Wm�Ș�h��]��m�nw*��m����kjۮ*ܮ[�|F���h��5�P��ڬsh3�Т�b_0ֶb�Z_��%�ꗛ�F��P���(���S�����L��'y�&�d1�������@!�����C�_FȈ�6����?o�'�������=�ɷ����b +���;���	^�O�=������m�t�QQ=,��h�L����o�K��,8���
a���~'?C>R��,e#/�~�q�ѱ6N��W��>�j�����������n�Euǚ�QO��#��ռ+���f�Vk�stA/;�=��g��X�L��"ï[L�Rj��fS��"�Z�|�zOƶʿP�-��}gˊ��#k�:���j9�Osj�5&�cD���q��U١`(-IkHT�7DR���y�ã�y�����N+n�;�GC-�i�Y�̛��(/���h���[鶍J��F��ٝo�,��eٙ�����_N�H������_[���	���	�?�E����I��, ��P���P�����>Q�m�� ������+���~Ȟ���B� (D�����?� ������7�����o�_������W��D��b�����g�"�?����N�g���?��9��?�����B������?w�2����3A��!��?���O������`��#+����� ���������O��B�G&(���ΐ� ����������?#���-${!�O����!���?���?��?迼��C������+���n(��9D�(D����@��C& �� ���w�?E���c&(���F!��������+���5�3��Y�X���Y��?�����������C���O��,P�7	�f� ���m�W�'��GX����?�AX�`ˑ7��`�Q.��A$N3��`Ia��s�û8�8�CQ4{}��kQ�'����S�_���)�GWz��Z9E��K��b����ô�Z���G�A�5���x70��t�����;ZzcNl��`J�`�wR�h���hM�eGbK�65�����՞��>��i@��B�Ұ3o-�f��P��=T�Jf�h���]�T��`(���?�C����V}�D����B�?���"��卿�������C����;㿺G����5�ri�/�M�:�ʸ�-���e�����2w��f0��[{jQ�Vj��P�Gӭ�t�bn��{|_�Vh��ݵ����^V��!�k$�D�#um+����P�M��~�x�_���ߌP���|�����P��/������_���_����s�4`(��È��?���k��v��S�?�f�&���f�v��w�6���+G�[�]�]"�d�/�U|�N�u �+��ZO�M-ɻ	�b(��[�!V�)ė�Ug�U"߳l}��հ�`VDut�
�13�����iFՐYRGʪ532�E�\k�Nxw�����II��UcC<ͅ�*e��鄱` �6�G��aXLu�e�Ï��M g��q�٭�v-2��]7x��4$����֊�����n�%G��mt�Ff��?��[��V'}]����I|�W�����d�)��@,�e�K��튜����fW��o��G������G���x��/�%�ϰ����������ǟ$p�LP���$ !��>��?;�A�WQ������Y���E���_�?�?g������	��CV����{��c)�Y���ٔ$�?<��n�Xλ#vk�X��i\��Ů���?ʲ`��H����E�^2n����J��{��0����C޻��}�y��5b%�[�7OS��!���K+I]&��ĵ�ٶ���b��eZ5�!�j�b���7s��j{��,E�Ԯ+H�֧��¯�,)����ʱ�\��T�힉�⦊�̴�Z����ػ�g5�5�;���u�NysXdsjz��Dp�]��r�E���}@��I4������Jb ������ޥ���ށ�nP:����e��>����7u~��u�ۚ��\�>3<ӿ����ƣt�҄;���X��K���ѶVe��JTD~�X�n*Due`����w��/��V����8,f��!͢.�vء�r2e#f6���ރp#t3�Z��:cXe��a��TOK:,y���`w���B�և=��	?���R�?�&���愜���F�5U�L�1�n�tTM�^7<�H��)�V7���:�#�VGU��%��~#�����O���|�#��y�2��"�I}Gs5�p>��[u�3�F�	�\b��5���o��K�}�\��
��-���O��;�������[��� ��x�ʋ���������迷Ƿ��S��S?������F�����+P��4���:����'��:!!ξ���}��o�1��+�������7���w��]�~���~J͉�M�=��&�#9R��A�h��N��龵�{h��!�6oV�/�����i�b8���4���H�<��~�����n?��OՄ��l9���ܤJQ�*n��d���1��SF��OL���c��q\�g�����MPdd�(|=�&���D�z��P+�kG�)���6�6����oO���ú�q�px�({�����(���n�@������O����I�(R3i˦�t2�DP�aj��*��Y#h=K%0C�t	J�k���v(�����_N����F��5:Bm�#�P�۪�A"|��F9���t��_�-�j��W� ��kQ��?5 o���y���?+�\�I|y�����S5���J���M�������ȅ��,�tx-# ��/��A���7�_����� /����_�6����/|k����h��*s����tv��@�{�����_�^�e�a�k����}_'fr���{]�ZD�8A��3~$�:���]	�.�>v�M�L�,�?.K&+�}����w��:s�[׮����u�qc�Mݝ"�������I��V�8r��~��T���cs1����������z�(����k��Aۈ��[�Q�T���g|��Vkx�e��|��v��N	?��0ɥ��p���u&i]�}W,�$҆��ޡCl,��KV�y�[���RS{۲8��[Ǝ����D�sS�o��p�H6�Qw-}F�q11��t=/AR{bk��x�v����`�8�ŏpZl��k:�@1���X�mt-#(��8�����g.��Q��>� �� ��t�%��[����A���+��@�ҡ��m�7����A�7����@����;׀ .�2��������`��8����d�P
��N�������#���?������o2�_��}� _A��{���(�S7�@�ߜ��߄��� ���x����.(��A]�R �?����?k�z�����P�u!
�����?~���?���A]�b�����8������� �?<.J���;�_���
� )�p ����_)��v��������RJa�߫�P� �@�P�� ��@���@]��������0�_����.D1(����������� �?�����w�?�����P�9�/��l�W
���� �_��$���B)��_@�?������R�?��?�P��6�Q�	`�`�?��+�������	����P�@4�Z�^�1�\jf3p�T�f�&��T�I�4����!p�#T�DH�C�V��ώ2�����A�>xa���$5�*-a~���&c	L���q+;x=���qϟ�ɊH�f�E�H���I�!�vqs(ltI��-���<氭`b�{�����MW�:���b�Q���X�ݎ�^Xꡇ��5�匥�#{��2;t	�3U�VC�I�gŅ_���6`,�3�R�7��>��O���I}�K�2����gq(l��]0�[�a��_q(�����P(�_~�)5���2�?���Ï��X��`�1�cSx�"PB��I]7�iҵ,w��]�X����j���ɺ���FkO��� �6<��<�wP��d����~���͚o[�x)�l�Xcq�ܮ䩯.��Zp���Su���(������[
�u�Iƫ��R����� �@����_���_Q���C)�A��?�<���g�����z]+AdmԁY�8��)�������g�BDm�~��ŗ�6襷�A$��lS�@�7\�ǝ�n��6Y�4V�h;L�33�V�T��K�T��T�m���o!� �v\u�TE��t�:�}Bh�4��v���.��٭l@�Y���p,\n����`�?�)$s�U�����Y�.IR����|�#�<�X��|/%�B�I��k0������u������7:{���D������9����0�c���}�FQ2�yQ�3��c�MpM�H2��"����tz��e�(�?�7��7 ��D��[�ȝ���R�?u���"���@~����e�?0&���������E�����V�xl ��_8��w���'��/��}1������M�� �O.(��*��#/����Q��@�GP��|\�B��w�� �+��@�"���������0���A��"P
������@��\����S���~���bz�E�g�Ǯ@f���o�?�Q��z�P��?���%V@ߗ��>�~d?��܏,�zE��Î����k��ս�.�W�9񰩰'�Ѥv$G�U>�����>>ݷ�u��<D��ͪ�!��Ӳu��<�У@L��g"ڜ�f^C�)�'Y�/��y�״_�Nޯ�	'�a�r��)V�I��bU�l�:�yc����4_��t?�qf�qݟ�:�Ǟ7A��1�����q[!4X���8ѡV�׎�s$Rx�m�7l�5���ߞJ+�u����(Q��q��`��0��^4/�b< ���������C����x�D)��;��@��| ���_����U��O����P������k� ��c�R�?��/e��;[ ���?��/߲�y>��Q�Q�N7��3#��ܵF������oX?|�?ID����uo����xMS�� ��?s �}�m�����-�[�ī:LRY^�ް#��.�4�64"����F��6�v�6�aLo�52�m����KH{B~= ʒ �J �%�Q� a�#YӖ[��B�(����x����eh��&V�Q}�w�H]S8�%����c��C0{U�t�N"��H���3T�&����f�w������rB���c�/�C��������5���#�?��?^�)]�Q�I��Z�UcYC4�$��5��LC�A����b��nhi�i
[�����e��{�?A�>���?GԂ:�Ok��"�N�DDN#�����`���l��<�W��?���f����UՃP���'8�Ykׅ�5!%v`�T���/e�D;Xuu���9��i9md&�fȐ�|�#+%�����E�P��8;�gM�����2����+���S����&��X��xD�����W~��Lw��^5��(���xx�������v��b��ĉ����#�ܑ؎G[,o�w>��\��[S
��P�3�6��&6��Ǯ���a qO�tܧ��w7Qp�72gǀ��Z�c����"(��y���_WA��P��/��U@����_ ����+��4`!(��#���[�o��?����ڶ�S�7a�����x��7!�����9�G������ ^� T�V�S]�����T9�
���D���ݩ���Ƥ�ES�T��pM_-h*>��p�l�֓���y"�vK"Yk������Xwű���2�t�2ISy�y��\�V2gYe�d��'��2n�I��2_ ��0`��?l�[M�~<�dZ�8> =sS��C�g��/_�\zi�>4��Lvu��\Hϥ��u�Oz��p ��1�	ku3��F7u���'��W�����k-�]sdn����m�}���zܶ�=:��	&�Z�����x��ڼ���	�?���&�7��q�O��Uc�7��Q�s��p��9�2�[�_I�����c��O���OG�K�l¸�`؁�}��>3j��K�C���C���A�1רp�N���g"'�����`��F_W�>>^���'-[��{�l����+.4��^8:�ܩ~Y�>���g��\W?/)���x����&q��)���o|c�%�/�?0�"��_.�����Ú����pp��Ư�N�#7�?+A��qEu���T=A�W���;�z�:}����.4 f�5���W��N�e{CU�ĶQ�wah��[:a��&<B�4���/����J�O����w���2��ao<���E���w��|W���+A�L?�{��_�-����>��������,S�ಮ�޼��|����_K���]Py���>Q��jn�J��k,-#�\ަJ���_�t3���t��r�Jb���|�񭊛�[�����D�Ψ|N��3}I�7��߮f���<��2t{S��{��E�a_]�݅`/7�2/���W���Mh�/m�����������w�Q���%1g�6b�?]<�:2�#��`����+��$�>;������ >t�}��mH�y��9�,ae�yi]��/e�{ՅYe��^��ԟ���9z���r�   ����Q0
� ;�#  