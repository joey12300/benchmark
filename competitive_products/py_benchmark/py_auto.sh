#!/bin/bash

##########################################
#                                        #
#      usage                             #
#      export the BENCHMARK_ROOT         #
#      export the PYTORCH_BENCHMARK_ROOT #
#                                        #
##########################################


cur_model_list=(detection pix2pix stargan image_classification)
export https_proxy=http://172.19.56.199:3128
export http_proxy=http://172.19.56.199:3128


######################
environment(){
apt-get update
apt-get install wget
apt-get install vim
pip uninstall torch-nightly -y
pip uninstall tensorflow
#conda remove wrapt --y
#pip uninstall setuptools -y
#pip install setuptools>=41.0.0
pip install tensorflow
pip install transformers

package_check_list=(pytest Cython opencv-python future pycocotools matplotlib networkx fasttext visdom)
    for package in ${package_check_list[@]}; do
        if python -c "import ${package}" >/dev/null 2>&1; then
            echo "${package} have already installed"
        else
            echo "${package} NOT FOUND"
            pip install ${package}
            echo "${package} installed"
        fi
done
}


#################pip packages
prepare(){
export BENCHMARK_ROOT=/ssd3/heya/tensorflow/benchmark_push/benchmark/
export PYTORCH_BENCHMARK_ROOT=${BENCHMARK_ROOT}/competitive_products/py_benchmark

export datapath=/ssd1/ljh/dataset

cur_timestaps=$(date "+%Y%m%d%H%M%S")
export CUR_DIR=${PYTORCH_BENCHMARK_ROOT}/${cur_timestaps}_result/
export LOG_DIR=${CUR_DIR}/LOG
export RES_DIR=${CUR_DIR}/RES
export MODEL_PATH=${CUR_DIR}/py_models

mkdir -p ${LOG_DIR}
mkdir -p ${RES_DIR}
mkdir -p ${MODEL_PATH}

}

#########detection
detection(){
curl_model_path=${MODEL_PATH}
cd ${curl_model_path}

cp -r ${BENCHMARK_ROOT}/static_graph/Detection/pytorch ${curl_model_path}/pytorch_detection
cd ${curl_model_path}/pytorch_detection
ln -s ${datapath}/COCO17 ./Detectron/detectron/datasets/data/coco
rm ${curl_model_path}/pytorch_detection/run_detectron.sh
cp ${BENCHMARK_ROOT}/static_graph/Detection/pytorch/run_detectron.sh ${curl_model_path}/pytorch_detection/

model_list=(mask_rcnn_fpn_resnet mask_rcnn_fpn_resnext retinanet_rcnn_fpn)
for model_name in ${model_list[@]}; do
    echo "----------------${model_name}"
    echo "------1-----------}"
    CUDA_VISIBLE_DEVICES=0 bash run_detectron.sh speed ${model_name} sp ${LOG_DIR} > ${RES_DIR}/${model_name}_1.res 2>&1
    sleep 60
    echo "------8-----------"
    CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run_detectron.sh speed ${model_name} sp ${LOG_DIR} > ${RES_DIR}/${model_name}_8.res 2>&1
    sleep 60
    
done 
}

######################pix2pix
pix2pix(){
curl_model_path=${MODEL_PATH}
cd ${curl_model_path}
echo "--1"${curl_model_path}
echo "--2"${PYTORCH_BENCHMARK_ROOT}

git clone https://github.com/chengduoZH/pytorch-CycleGAN-and-pix2pix

echo "git success"
cp ${BENCHMARK_ROOT}/static_graph/GAN_models/PytorchGAN/run.sh ${curl_model_path}/pytorch-CycleGAN-and-pix2pix/run_pix2pix.sh
cd ${curl_model_path}/pytorch-CycleGAN-and-pix2pix
git checkout benchmark
ln -s ${datapath}/pytorch_pix2pix_data ${curl_model_path}/pytorch-CycleGAN-and-pix2pix/dataset

echo "----------------pix2pix"
    echo "----1----}"
CUDA_VISIBLE_DEVICES=0 bash run_pix2pix.sh speed ${LOG_DIR} > ${RES_DIR}/pix2pix_1.res 2>&1
#sleep 60
#    echo "----8----}" # not run
#CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run_pix2pix.sh speed ${LOG_DIR} > ${RES_DIR}/pix2pix_8.res 2>&1

}


##################stargan
stargan(){
curl_model_path=${MODEL_PATH}
cd ${curl_model_path}

git clone https://github.com/yunjey/stargan.git
cd ${curl_model_path}/stargan
cp ${BENCHMARK_ROOT}/static_graph/StarGAN/pytorch/run_stargan.sh ${curl_model_path}/stargan 
mkdir -p ${curl_model_path}/stargan/data/celeba
ln -s ${datapath}/CelebA/Anno/* ${curl_model_path}/stargan/data/celeba
ln -s ${datapath}/CelebA/Img/img_align_celeba/ ${curl_model_path}/stargan/data/celeba/images
echo "----------------stargan"
    echo "----1----}"
CUDA_VISIBLE_DEVICES=0 bash run_stargan.sh train speed ${LOG_DIR} > ${RES_DIR}/stargan_1.res 2>&1
#sleep 60
#    echo "----8----}" # not run
#CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run_stargan.sh train speed ${LOG_DIR} > ${RES_DIR}/stargan_8.res 2>&1
}


#######################image_class
image_classification(){
curl_model_path=${MODEL_PATH}
cd ${curl_model_path}

cp -r ${BENCHMARK_ROOT}/static_graph/image_classification/pytorch ${curl_model_path}/pytorch_image_class
cd ${curl_model_path}/pytorch_image_class
ln -s /ssd3/ljh/cts_ce/dataset/data/ImageNet/train ${curl_model_path}/pytorch_image_class/SENet/ImageData/ILSVRC2012_img_train
ln -s /ssd3/ljh/cts_ce/dataset/data/ImageNet/val ${curl_model_path}/pytorch_image_class/SENet/ImageData/ILSVRC2012_img_val


cp ${BENCHMARK_ROOT}/static_graph/image_classification/pytorch/run_vision.sh ${curl_model_path}/pytorch_image_class
cp ${BENCHMARK_ROOT}/static_graph/image_classification/pytorch/run_senet.sh ${curl_model_path}/pytorch_image_class


model_list=(resnet101 resnet50)
for model_name in ${model_list[@]}; do
    echo "----------------${model_name}"
    echo "------1-----------}"
    CUDA_VISIBLE_DEVICES=0 bash run_vision.sh speed 32 ${model_name} sp ${LOG_DIR} > ${RES_DIR}/image_${model_name}_1.res 2>&1
    sleep 60
    #echo "------8-----------"  # not run
    #CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run_vision.sh speed 32 ${model_name} sp ${LOG_DIR} > ${RES_DIR}/image_${model_name}_8.res 2>&1
done
#------------
echo "----------------se_resnet50"
    echo "----1----}"
CUDA_VISIBLE_DEVICES=0 bash run_senet.sh speed 32 se_resnext_50 sp ${LOG_DIR} > ${RES_DIR}/image_se_resnet50_1.res 2>&1
sleep 60
#    echo "----8----}"  #not run 
#CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 bash run_senet.sh speed 32 se_resnext_50 sp  ${LOG_DIR} > ${RES_DIR}/image_se_resnet50_8.res 2>&1 

}

run(){
       for model_name in ${cur_model_list[@]}
       do
           begin_timestaps=$(date "+%Y_%m_%d#%H-%M-%S")
           echo "=====================${model_name} run begin==================${begin_timestaps}"
           $model_name
           sleep 60
           end_timestaps=$(date "+%Y_%m_%d#%H-%M-%S")
           echo "*********************${model_name} run end!!******************${end_timestaps}"
       done
}
environment # according to the actual condition
prepare
run

sh ${PYTORCH_BENCHMARK_ROOT}/scripts/py_final_ana.sh ${CUR_DIR}
