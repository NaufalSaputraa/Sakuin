# Sakuin Gemma 4 E2B QLoRA Tuning - RTX 4060 8GB

## Setup (sekali)
pip install unsloth trl transformers datasets accelerate bitsandbytes torch

## Cek VRAM
nvidia-smi # harus lihat RTX 4060 8GB, CUDA 12.1

## Dataset
Buat tuning/dataset.jsonl 100 baris transaksi Indonesia:
{"instruction": "Tambahkan pengeluaran warung 20rb", "input": "", "output": "{\"amount\": 20000, \"category\": \"warung\", \"title\": \"Warung\"}"}

## Run
python tuning/finetune_gemma_qlora.py
# Output: tuning/gemma-4-e2b-sakuin-lora/adapters.safetensors (~50MB)
# Merge: python -c "from unsloth import FastLanguageModel; model,_=FastLanguageModel.from_pretrained('tuning/gemma-4-e2b-sakuin-lora'); model.save_pretrained_merged('tuning/gemma-4-e2b-sakuin-merged', tokenizer, save_method='merged_16bit')"

## Catatan RTX 4060 8GB
- Full fine-tuning 2.39GB butuh 22-24GB -> OOM, jangan.
- QLoRA 4-bit r=32 alpha=64 -> ~6.5GB, batch 2 + grad accum 4 + bf16 -> muat di 8GB, 1-2 jam.
- Prompt tuning di gemma_llm_service.dart sudah aktif (ramah Indonesia) - LoRA hanya jika mau lebih powerful lagi.
