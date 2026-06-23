---
title: Azure + Terraform - Storage Account (2)
date: 2026-06-08
categories:
  - cloud
comments: true
tags:
  - azure
  - terraform
---
---

Disk     파티션        pv           vg         lv       사이즈        file system      mount point
sdb       sdb1     /dev/sdb1    jhjang   jhjang1    3.3G            ext3               /f1
                                jhjang2    3.3G            ext4               /f2
                                jhjang3   나머지G         xfs                /f3


fdisk /dev/sdb
명령어를 모른다면? m

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609094718590.png)

- 선호방식
lvscan 선호: 장치명도 나옴

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609100021502.png)


vgdisplay

![](../../../assets/images/Security/KimSeongDae/2026-06-09-Terraform_Storage%202/file-20260609095827832.png)

![](../../../assets/images/Security/KimSeongDae/2026-06-09-Terraform_Storage%202/file-20260609095827832.png)


pvs



아 3.39기가 남았구나 라고 생각

---
삭제는거꾸로

mount삭제 -> file system 삭제 -> lvm 삭제 -> volumn group 삭제 -> pv 삭제 -> 파티션 삭제

umount
wipefs -a -f /dev/jhjang/jhjang1
lvremove /dev/jhjang/jhjang3
vgremove
pvremove
fdisk /dev/sdb -> d -> w

---
재생성

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609104326940.png)

이게 만들어지면 성공

확장

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609104525617.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609104713057.png)

3.3 -> 4.3 넘어감

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609105054797.png)

자동으로 늘어나있음

---
삭제과정

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609105302923.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609105345508.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609105619992.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609105739078.png)

![](../../../assets/images/Cloud/KimSeongDae/2026-06-09-azure-terraform-storage-02/file-20260609105813834.png)

마무리로 fdisk /dev/sdc 삭제, fdisk /dev/sdb 삭제

---

